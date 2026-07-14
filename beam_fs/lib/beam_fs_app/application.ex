defmodule BeamFsApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {BeamFs.Lib.Connection.Supervisor, []}
      ] ++ horde_children()

    opts = [strategy: :one_for_one, name: BeamFs.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    if clustered?() do
      BeamFs.Horde.Coordinator.start()
    end

    {:ok, sup}
  end

  defp horde_children do
    if clustered?() do
      [
        {BeamFs.Horde.Registry, []},
        {BeamFs.Horde.Supervisor, []}
      ]
    else
      []
    end
  end

  defp clustered? do
    node() != :nonode@nohost
  end
end
