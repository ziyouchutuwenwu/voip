import Config

config :beam_fs,
  freeswitch: [
    node: :"fs@10.0.2.222"
  ],
  sip: [
    users: [
      %{username: "1000", password: "123456", ip: "10.0.2.222"},
      %{username: "1001", password: "123456", ip: "10.0.2.222"},
      %{username: "1002", password: "123456", ip: "10.0.2.222"},
      %{username: "1003", password: "123456", ip: "10.0.2.222"}
    ]
  ]
