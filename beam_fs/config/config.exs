import Config

config :beam_fs,
  freeswitch: [
    node: :"fs@10.0.2.222"
  ],
  sip: [
    users: [
      %{username: "1111", password: "123456", ip: "10.0.2.222"},
      %{username: "2222", password: "123456", ip: "10.0.2.222"},
      %{username: "3333", password: "123456", ip: "10.0.2.222"},
      %{username: "4444", password: "123456", ip: "10.0.2.222"}
    ]
  ]
