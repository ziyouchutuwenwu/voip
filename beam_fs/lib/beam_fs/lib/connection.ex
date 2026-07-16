defmodule BeamFs.Lib.Connection do
  require Logger

  @max_reconnect_interval 60_000

  defstruct node: nil,
            connected: false,
            reconnect_timer: nil,
            reconnect_interval: 5_000

  def start_link(_opts) do
    pid = spawn_link(fn -> init() end)
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  def connected?, do: call(:connected?)
  def connected_node, do: call(:connected_node)

  def api(cmd, args \\ "", opts \\ []) do
    call({:api, cmd, args, opts})
  end

  def bgapi(cmd, args \\ "", opts \\ []) do
    call({:bgapi, cmd, args, opts})
  end

  def bind(section) do
    call({:bind, section})
  end

  def subscribe_events do
    call(:subscribe_events)
  end

  defp call(msg) do
    ref = make_ref()
    send(__MODULE__, {:call, {self(), ref}, msg})

    receive do
      {^ref, reply} -> reply
    end
  end

  defp init do
    Process.flag(:trap_exit, true)
    node = BeamFs.Config.Fetcher.fs_node()
    state = %__MODULE__{node: node}
    send(self(), {:connect})
    loop(state)
  end

  defp loop(state) do
    receive do
      {:call, {pid, ref}, :connected?} ->
        send(pid, {ref, state.connected})
        loop(state)

      {:call, {pid, ref}, :connected_node} ->
        send(pid, {ref, state.node})
        loop(state)

      {:call, {pid, ref}, {:api, cmd, args, opts}} ->
        handle_api(pid, ref, cmd, args, opts, state)
        loop(state)

      {:call, {pid, ref}, {:bgapi, cmd, args, opts}} ->
        handle_bgapi(pid, ref, cmd, args, opts, state)
        loop(state)

      {:call, {pid, ref}, {:bind, section}} ->
        result = do_bind(state.node, section)
        send(pid, {ref, result})
        loop(state)

      {:call, {pid, ref}, :subscribe_events} ->
        result = do_subscribe_events(state.node)
        send(pid, {ref, result})
        loop(state)

      {:connect} ->
        state = handle_connect(state)
        loop(state)

      {:nodedown, node} when node == state.node ->
        state = handle_nodedown(state)
        loop(state)

      {:nodedown, _other} ->
        loop(state)

      {:event, _data} = msg ->
        spawn(fn -> BeamFs.Lib.Event.handle(msg) end)
        loop(state)

      {:fetch, section, tag, key, value, uuid, params} ->
        Logger.info(
          "incoming fetch: section=#{inspect(section)} tag=#{inspect(tag)} key=#{inspect(key)} value=#{inspect(value)} uuid=#{inspect(uuid)} params=#{inspect(params)}"
        )

        node = state.node

        spawn(fn ->
          result = BeamFs.Lib.XmlFetcher.handle(node, section, tag, key, value, uuid, params)
          send({:fs, node}, {:fetch_reply, uuid, result})
        end)

        loop(state)

      {:ok, _job_uuid} ->
        loop(state)

      {:bgerror, _job_uuid, _error} ->
        loop(state)

      msg ->
        Logger.debug("unhandled: #{inspect(msg)}")
        loop(state)
    end
  end

  defp handle_api(pid, ref, cmd, args, opts, state) do
    if state.connected do
      timeout = Keyword.get(opts, :timeout, 10_000)
      send({:fs, state.node}, {:api, String.to_atom(cmd), args})

      receive do
        {:ok, result} -> send(pid, {ref, {:ok, result}})
        {:error, reason} -> send(pid, {ref, {:error, reason}})
      after
        timeout -> send(pid, {ref, {:error, :timeout}})
      end
    else
      send(pid, {ref, {:error, :not_connected}})
    end

    :ok
  end

  defp handle_bgapi(pid, ref, cmd, args, opts, state) do
    if state.connected do
      timeout = Keyword.get(opts, :timeout, 60_000)
      send({:fs, state.node}, {:bgapi, String.to_atom(cmd), args})

      receive do
        {:ok, result} -> send(pid, {ref, {:ok, result}})
        {:error, reason} -> send(pid, {ref, {:error, reason}})
      after
        timeout -> send(pid, {ref, {:error, :timeout}})
      end
    else
      send(pid, {ref, {:error, :not_connected}})
    end

    :ok
  end

  defp handle_connect(state) do
    case :net_kernel.connect_node(state.node) do
      true ->
        Logger.info("connected to freeswitch node: #{state.node}")
        :erlang.monitor_node(state.node, true)

        dialplan_bind = do_bind(state.node, :dialplan)
        Logger.info("dialplan bind result: #{inspect(dialplan_bind)}")

        dir_bind = do_bind(state.node, :directory)
        Logger.info("directory bind result: #{inspect(dir_bind)}")

        sub_result = do_subscribe_events(state.node)
        Logger.info("subscribe events result: #{inspect(sub_result)}")

        %{
          state
          | connected: true,
            reconnect_interval: 5_000
        }

      _ ->
        interval = state.reconnect_interval

        Logger.warning(
          "failed to connect to #{state.node}, retrying in #{div(interval, 1000)}s..."
        )

        next_interval = min(interval * 2, @max_reconnect_interval)
        timer = Process.send_after(self(), {:connect}, interval)

        %{state | reconnect_timer: timer, reconnect_interval: next_interval}
    end
  end

  defp handle_nodedown(state) do
    Logger.warning("freeswitch node #{state.node} disconnected, reconnecting...")
    :erlang.monitor_node(state.node, false)

    interval = state.reconnect_interval
    timer = Process.send_after(self(), {:connect}, interval)

    %{state | connected: false, reconnect_timer: timer}
  end

  defp do_bind(node, section) do
    send({:fs, node}, {:bind, section})

    receive do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    after
      5_000 -> {:error, :timeout}
    end
  end

  defp do_subscribe_events(node) do
    send({:fs, node}, :register_event_handler)

    receive do
      :ok ->
        send(
          {:fs, node},
          {:setevent, :CHANNEL_CREATE, :CHANNEL_ANSWER, :CHANNEL_HANGUP, :CHANNEL_BRIDGE,
           :CHANNEL_DESTROY, :CUSTOM, :"sofia::register", :"sofia::unregister"}
        )

        receive do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        after
          5_000 -> {:error, :timeout}
        end

      {:error, reason} ->
        {:error, reason}
    after
      5_000 -> {:error, :timeout}
    end
  end
end
