defmodule BeamFs.Lib.Connection do
  require Logger

  @max_reconnect_interval 60_000

  defstruct nodes: [],
            connected: MapSet.new(),
            reconnect_timers: %{},
            reconnect_intervals: %{}

  def start_link() do
    pid = spawn_link(fn -> init() end)
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  def connected?, do: call(:connected?)
  def connected_nodes, do: call(:connected_nodes)

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

  def fetch_reply(uuid, xml_string) do
    send(__MODULE__, {:fetch_reply, uuid, xml_string})
  end

  defp call(msg) do
    ref = make_ref()
    send(__MODULE__, {:call, {self(), ref}, msg})

    receive do
      {^ref, reply} -> reply
    end
  end

  defp init() do
    Process.flag(:trap_exit, true)

    %{nodes: nodes, cookie: cookie} = BeamFs.Config.Fetcher.fs_nodes()

    intervals = Map.new(nodes, fn n -> {n, 5_000} end)
    state = %__MODULE__{nodes: nodes, reconnect_intervals: intervals}

    :erlang.set_cookie(node(), cookie)
    Enum.each(nodes, fn n -> send(self(), {:connect, n}) end)
    loop(state)
  end

  defp loop(state) do
    receive do
      {:call, {pid, ref}, :connected?} ->
        send(pid, {ref, MapSet.size(state.connected) > 0})
        loop(state)

      {:call, {pid, ref}, :connected_nodes} ->
        send(pid, {ref, state.connected})
        loop(state)

      {:call, {pid, ref}, {:api, cmd, args, opts}} ->
        state = handle_api(pid, ref, cmd, args, opts, state)
        loop(state)

      {:call, {pid, ref}, {:bgapi, cmd, args, opts}} ->
        state = handle_bgapi(pid, ref, cmd, args, opts, state)
        loop(state)

      {:call, {pid, ref}, {:bind, section}} ->
        results = Enum.map(state.nodes, fn n -> do_bind(n, section) end)
        send(pid, {ref, results})
        loop(state)

      {:call, {pid, ref}, :subscribe_events} ->
        results = Enum.map(state.nodes, fn n -> do_subscribe_events(n) end)
        send(pid, {ref, results})
        loop(state)

      {:connect, node} ->
        state = handle_connect(node, state)
        loop(state)

      {:nodedown, node} ->
        state = handle_nodedown(node, state)
        loop(state)

      {:event, _data} = msg ->
        spawn(fn -> BeamFs.Lib.Event.handle(msg) end)
        loop(state)

      {:fetch, section, tag, key, value, uuid, params} ->
        Logger.info(
          "incoming fetch: section=#{inspect(section)} tag=#{inspect(tag)} key=#{inspect(key)} value=#{inspect(value)} uuid=#{inspect(uuid)} params=#{inspect(params)}"
        )

        spawn(fn ->
          BeamFs.Lib.XmlFetcher.handle(section, tag, key, value, uuid, params)
        end)

        loop(state)

      {:ok, _job_uuid} ->
        loop(state)

      {:bgerror, _job_uuid, _error} ->
        loop(state)

      {:fetch_reply, uuid, xml_string} ->
        node = pick_connected(state)

        Logger.info(
          "fetch_reply to #{inspect(node)} uuid=#{inspect(uuid)} size=#{byte_size(xml_string)}"
        )

        if node, do: send({:fs, node}, {:fetch_reply, uuid, xml_string})
        loop(state)

      msg ->
        Logger.debug("unhandled: #{inspect(msg)}")
        loop(state)
    end
  end

  defp pick_connected(state) do
    Enum.find(state.nodes, fn n -> MapSet.member?(state.connected, n) end)
  end

  defp handle_api(pid, ref, cmd, args, opts, state) do
    case pick_connected(state) do
      nil ->
        send(pid, {ref, {:error, :not_connected}})

      node ->
        timeout = Keyword.get(opts, :timeout, 10_000)
        send({:fs, node}, {:api, String.to_atom(cmd), args})

        receive do
          {:ok, result} -> send(pid, {ref, {:ok, result}})
          {:error, reason} -> send(pid, {ref, {:error, reason}})
        after
          timeout -> send(pid, {ref, {:error, :timeout}})
        end
    end

    state
  end

  defp handle_bgapi(pid, ref, cmd, args, opts, state) do
    case pick_connected(state) do
      nil ->
        send(pid, {ref, {:error, :not_connected}})

      node ->
        timeout = Keyword.get(opts, :timeout, 60_000)
        send({:fs, node}, {:bgapi, String.to_atom(cmd), args})

        receive do
          {:ok, result} -> send(pid, {ref, {:ok, result}})
          {:error, reason} -> send(pid, {ref, {:error, reason}})
        after
          timeout -> send(pid, {ref, {:error, :timeout}})
        end
    end

    state
  end

  defp handle_connect(node, state) do
    interval = Map.get(state.reconnect_intervals, node, 5_000)

    case :net_kernel.connect_node(node) do
      true ->
        Logger.info("connected to freeswitch node: #{node}")
        :erlang.monitor_node(node, true)
        dialplan_bind = do_bind(node, :dialplan)
        Logger.info("dialplan bind result: #{inspect(dialplan_bind)}")
        dir_bind = do_bind(node, :directory)
        Logger.info("directory bind result: #{inspect(dir_bind)}")
        sub_result = do_subscribe_events(node)
        Logger.info("subscribe events result: #{inspect(sub_result)}")

        %{
          state
          | connected: MapSet.put(state.connected, node),
            reconnect_timers: Map.delete(state.reconnect_timers, node),
            reconnect_intervals: Map.put(state.reconnect_intervals, node, 5_000)
        }

      _ ->
        Logger.warning("failed to connect to #{node}, retrying in #{div(interval, 1000)}s...")
        next_interval = min(interval * 2, @max_reconnect_interval)
        timer = Process.send_after(self(), {:connect, node}, interval)

        %{
          state
          | connected: MapSet.delete(state.connected, node),
            reconnect_timers: Map.put(state.reconnect_timers, node, timer),
            reconnect_intervals: Map.put(state.reconnect_intervals, node, next_interval)
        }
    end
  end

  defp handle_nodedown(node, state) do
    if MapSet.member?(state.connected, node) do
      Logger.warning("freeswitch node #{node} disconnected, reconnecting...")
      :erlang.monitor_node(node, false)

      interval = Map.get(state.reconnect_intervals, node, 5_000)
      timer = Process.send_after(self(), {:connect, node}, interval)

      %{
        state
        | connected: MapSet.delete(state.connected, node),
          reconnect_timers: Map.put(state.reconnect_timers, node, timer)
      }
    else
      state
    end
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
    # Register this process as the event handler (sets listener->event_process.pid)
    send({:fs, node}, :register_event_handler)

    receive do
      :ok ->
        # Subscribe to specific events
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
