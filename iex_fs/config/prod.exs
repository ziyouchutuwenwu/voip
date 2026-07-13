import Config

config :fs_node, FsNodeApp.Repo,
  database: "/data/fs_node.db",
  pool_size: 10

config :fs_node, FsNodeWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")],
  url: [host: System.get_env("HOST", "0.0.0.0")],
  server: true
