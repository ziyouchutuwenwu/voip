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
    Cmd.ivr_call("2222",
      play: "/usr/local/share/freeswitch/sounds/ivr-prompt.wav",
      dtmf_map: %{
        "1" => {:play, "/usr/local/share/freeswitch/sounds/ivr-prompt.wav"},
        "2" => {:transfer, "3333"}
      }
    )
  end

  def call() do
    Cmd.call("1111")
  end
end
