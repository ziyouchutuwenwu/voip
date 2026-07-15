defmodule BeamFs.Lib.Event do
  def handle({:event, data}) when is_list(data) do
    BeamFs.Events.EventHandler.handle_event(data)
  end

  def handle(_), do: :ok
end
