import Config

if config_env() == :prod do
  cookie = System.fetch_env!("FS_COOKIE")
  fs_host = System.get_env("FS_HOST", "10.0.2.1")

  config :fs_node, :freeswitch,
    node_name: String.to_atom("fs@#{fs_host}"),
    cookie: cookie
end
