defmodule BeamFs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: BeamFs.EventRegistry},
      BeamFs.Lib.Connection.Supervisor,
    ]

    opts = [strategy: :one_for_one, name: BeamFs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
