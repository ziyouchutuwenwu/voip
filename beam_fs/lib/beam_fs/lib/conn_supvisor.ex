defmodule BeamFs.Lib.Connection.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      %{
        id: BeamFs.Lib.Connection,
        start: {BeamFs.Lib.Connection, :start_link, [opts]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
