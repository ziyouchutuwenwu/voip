import Config

config :fs_node, ecto_repos: [FsNodeApp.Repo]

config :fs_node, :freeswitch,
  node_name: :"fs@10.0.2.1",
  cookie: "123456",
  reconnect_interval: 5_000

config :fs_node, :sip,
  default_domain: "10.0.2.1"

config :fs_node, FsNodeApp.Repo,
  database: Path.expand("../fs_node.db", __DIR__),
  pool_size: 5,
  journal_mode: :wal,
  cache_size: -64000

config :fs_node, FsNodeWeb.Endpoint,
  http: [port: 4000],
  url: [host: "0.0.0.0"],
  server: true

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
