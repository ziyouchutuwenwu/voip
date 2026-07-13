defmodule FsNode.Lib.Connection do
  use GenServer
  require Logger

  @config_key :freeswitch
  @max_reconnect_interval 60_000

  defstruct [
    :freeswitch_node,
    connected: false,
    reconnect_timer: nil,
    reconnect_interval: 5_000
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def connected?, do: GenServer.call(__MODULE__, :connected?)
  def freeswitch_node, do: GenServer.call(__MODULE__, :freeswitch_node)

  def api(cmd, args \\ "", opts \\ []) do
    GenServer.call(__MODULE__, {:api, cmd, args, opts}, :infinity)
  end

  def bgapi(cmd, args \\ "", opts \\ []) do
    GenServer.call(__MODULE__, {:bgapi, cmd, args, opts}, :infinity)
  end

  def bind(section) do
    GenServer.call(__MODULE__, {:bind, section})
  end

  def subscribe_events do
    GenServer.call(__MODULE__, :subscribe_events)
  end

  def fetch_reply(uuid, xml_string) do
    GenServer.cast(__MODULE__, {:fetch_reply, uuid, xml_string})
  end

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    config = Application.get_env(:fs_node, @config_key) || raise "Missing config :fs_node, :freeswitch"
    node_name = config[:node_name] || raise "Missing :node_name in freeswitch config"
    cookie = config[:cookie] || raise "Missing :cookie in freeswitch config"

    set_node_name()

    if node() == :nonode@nohost do
      Logger.warning("Not in a distributed node, skipping FreeSWITCH connection")
      {:ok, %__MODULE__{freeswitch_node: node_name, connected: false}}
    else
      :erlang.set_cookie(node(), String.to_atom(cookie))
      send(self(), :connect)
      {:ok, %__MODULE__{freeswitch_node: node_name}}
    end
  end

  @impl true
  def handle_call(:connected?, _from, %{connected: c} = s), do: {:reply, c == true, s}
  def handle_call(:freeswitch_node, _from, %{freeswitch_node: n} = s), do: {:reply, n, s}

  def handle_call({:api, cmd, args, opts}, _from, %{freeswitch_node: node, connected: true} = state) do
    timeout = Keyword.get(opts, :timeout, 10_000)
    send({:fs, node}, {:api, String.to_atom(cmd), args})
    receive do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    after
      timeout -> {:reply, {:error, :timeout}, state}
    end
  end

  def handle_call({:api, _cmd, _args, _opts}, _from, %{connected: false} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:bgapi, cmd, args, opts}, _from, %{freeswitch_node: node, connected: true} = state) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    send({:fs, node}, {:bgapi, String.to_atom(cmd), args})
    receive do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    after
      timeout -> {:reply, {:error, :timeout}, state}
    end
  end

  def handle_call({:bgapi, _cmd, _args, _opts}, _from, %{connected: false} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:bind, section}, _from, %{freeswitch_node: node} = state) do
    result = do_bind(node, section)
    {:reply, result, state}
  end

  def handle_call(:subscribe_events, _from, %{freeswitch_node: node} = state) do
    result = do_subscribe_events(node)
    {:reply, result, state}
  end

  @impl true
  def handle_info(:connect, %{freeswitch_node: node, reconnect_interval: interval} = state) do
    case :net_kernel.connect_node(node) do
      true ->
        Logger.info("Connected to FreeSWITCH node: #{node}")
        :erlang.monitor_node(node, true)
        do_bind(node, :dialplan)
        do_subscribe_events(node)
        Phoenix.PubSub.broadcast(FsNode.PubSub, "freeswitch:connection", :connected)
        {:noreply, %{state | connected: true, reconnect_timer: nil, reconnect_interval: 5_000}}

      false ->
        Logger.warning("Failed to connect, retrying in #{div(interval, 1000)}s...")
        next_interval = min(interval * 2, @max_reconnect_interval)
        timer = Process.send_after(self(), :connect, interval)
        {:noreply, %{state | connected: false, reconnect_timer: timer, reconnect_interval: next_interval}}
    end
  end

  @impl true
  def handle_info({:nodedown, node}, %{freeswitch_node: node} = state) do
    Logger.warning("FreeSWITCH node #{node} disconnected, reconnecting...")
    :erlang.monitor_node(node, false)
    Phoenix.PubSub.broadcast(FsNode.PubSub, "freeswitch:connection", :disconnected)
    timer = Process.send_after(self(), :connect, state.reconnect_interval)
    {:noreply, %{state | connected: false, reconnect_timer: timer}}
  end

  def handle_info({:nodedown, _other}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:event, _data} = msg, state) do
    FsNode.Lib.Event.handle(msg)
    {:noreply, state}
  end

  @impl true
  def handle_info({:fetch, section, tag, key, value, uuid, _params}, state) do
    FsNode.Lib.FetchHandler.handle(section, tag, key, value, uuid)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("Unhandled: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:fetch_reply, uuid, xml_string}, %{freeswitch_node: node} = state) do
    send({:fs, node}, {:fetch_reply, uuid, xml_string})
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.reconnect_timer, do: Process.cancel_timer(state.reconnect_timer)
    :ok
  end

  defp do_bind(node, section) do
    send({:fs, node}, {:bind, section})

    receive do
      :ok ->
        Logger.info("Bound #{section}")
        :ok
      {:error, reason} ->
        Logger.warning("Bind #{section} failed: #{reason}")
        {:error, reason}
    after
      5_000 ->
        Logger.warning("Bind #{section} timeout")
        {:error, :timeout}
    end
  end

  defp do_subscribe_events(node) do
    send({:fs, node}, {:setevent, :CHANNEL_CREATE, :CHANNEL_ANSWER, :CHANNEL_HANGUP,
                        :CHANNEL_BRIDGE, :CHANNEL_DESTROY,
                        :SOFIA_REGISTER, :SOFIA_UNREGISTER})

    receive do
      :ok ->
        Logger.info("Events subscribed")
        :ok
      {:error, reason} ->
        Logger.warning("Event subscribe failed: #{reason}")
        {:error, reason}
    after
      5_000 ->
        Logger.warning("Event subscribe timeout")
        {:error, :timeout}
    end
  end

  defp set_node_name do
    host = :inet.gethostname() |> elem(1) |> List.to_string()
    case :net_kernel.start([:"fs_node@#{host}", :longnames]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, reason} -> Logger.warning("Node name: #{inspect(reason)}")
    end
  end
end
