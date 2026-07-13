import Config

config :fs_node, FsNodeWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  server: true

config :phoenix, :plug_init_mode, :runtime
