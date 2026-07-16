defmodule Demo do
  # iex --name aaa@127.0.0.1 --cookie 123456 -S mix
  def show_register do
    # BeamFs.Lib.Connection.connected?()
    # BeamFs.Lib.Connection.connected_nodes()
    # BeamFs.Lib.Api.status()
    BeamFs.Lib.Api.show_registrations()
    # BeamFs.Lib.Api.show_channels()
  end

  def call() do
    BeamFs.Lib.Api.show_channels()
    BeamFs.Lib.Api.api("uuid_answer", "<通道UUID>")
  end
end
