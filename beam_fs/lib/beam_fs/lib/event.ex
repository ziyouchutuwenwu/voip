defmodule BeamFs.Lib.Event do
  require Logger

  def handle({:event, data}) when is_list(data) do
    if node() != :nonode@nohost do
      name = {:via, Horde.Registry, {BeamFs.Horde.Registry, :event_coordinator}}

      case GenServer.whereis(name) do
        nil ->
          Logger.warning("no coordinator found, processing locally")
          BeamFs.Events.EventHandler.handle_event(data)

        pid ->
          send(pid, {:process_event, data})
      end
    else
      BeamFs.Events.EventHandler.handle_event(data)
    end
  end

  def handle(_), do: :ok
end
