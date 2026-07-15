import Config

config :beam_fs,
  # freeswitch 节点
  freeswitch: [
    nodes: [:"fs@10.0.2.222"]
  ],
  # 代表已经创建好的 sip 用户
  sip: [
    users: [
      %{username: "1000", password: "123456"},
      %{username: "1001", password: "123456"},
      %{username: "1002", password: "123456"},
      %{username: "1003", password: "123456"}
    ]
  ]
