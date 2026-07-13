import Config

config :fs_node, FsNodeApp.Repo,
  database: ":memory:",
  pool_size: 2,
  journal_mode: :wal,
  cache_size: -64000

config :fs_node, FsNodeWeb.Endpoint,
  http: [port: 4001],
  url: [host: "localhost"],
  server: false

config :phoenix, :plug_init_mode, :runtime

config :logger, level: :warning
