defmodule FsNodeApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FsNodeApp.Repo,
      FsNode.Lib.Connection,
      {Phoenix.PubSub, name: FsNode.PubSub},
      FsNodeWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: FsNode.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
