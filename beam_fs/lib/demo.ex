defmodule Demo do
  require Logger
  # iex --name aaa@127.0.0.1 --cookie 123456 -S mix
  def info do
    connected = BeamFs.Lib.Connection.connected?()
    Logger.debug("connected #{inspect(connected)}")

    status = BeamFs.Lib.Api.status()
    Logger.debug("status #{inspect(status)}")
  end

  def registration do
    BeamFs.Lib.Api.show_registrations()
  end

  def ivr() do
    Cmd.ivr_call("1001",
      say: "按1转销售，按2转客服",
      dtmf_map: %{
        "1" => {:play, "/sounds/intro.wav"},
        "2" => {:transfer, "1002"}
      }
    )
  end

  def call() do
    Cmd.call("1000")
  end
end
