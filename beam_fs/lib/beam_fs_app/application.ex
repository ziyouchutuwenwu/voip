defmodule BeamFsApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Highlander, BeamFs.Lib.Connection.Supervisor},
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
