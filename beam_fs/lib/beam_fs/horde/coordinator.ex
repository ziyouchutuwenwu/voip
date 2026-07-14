defmodule BeamFs.Horde.Coordinator do
  use GenServer

  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, :event_coordinator)

    GenServer.start_link(__MODULE__, opts,
      name: {:via, Horde.Registry, {BeamFs.Horde.Registry, name}}
    )
  end

  def start(name \\ :event_coordinator) do
    child_spec = %{
      id: name,
      start: {__MODULE__, :start_link, [[name: name]]},
      restart: :permanent,
      shutdown: 5_000,
      type: :worker
    }

    case Horde.DynamicSupervisor.start_child(BeamFs.Horde.Supervisor, child_spec) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def init(_opts) do
    Logger.info("event coordinator started on #{node()}")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:process_event, data}, state) do
    spawn(fn -> BeamFs.Events.EventHandler.handle_event(data) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
