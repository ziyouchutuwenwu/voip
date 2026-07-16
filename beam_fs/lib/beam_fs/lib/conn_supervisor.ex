defmodule BeamFs.Lib.Connection.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      %{
        id: BeamFs.Lib.Connection,
        start: {BeamFs.Lib.Connection, :start_link, [[]]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
