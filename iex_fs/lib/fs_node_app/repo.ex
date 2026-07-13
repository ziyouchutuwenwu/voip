defmodule FsNodeApp.Repo do
  use Ecto.Repo,
    otp_app: :fs_node,
    adapter: Ecto.Adapters.SQLite3
end
