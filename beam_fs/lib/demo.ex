defmodule Demo do
  # iex --name aaa@127.0.0.1 --cookie 123456 -S mix
  def demo do
    # BeamFs.Lib.Connection.connected?()
    # BeamFs.Lib.Connection.connected_nodes()
    # BeamFs.Lib.Api.status()
    BeamFs.Lib.Api.show_registrations()
    # BeamFs.Lib.Api.show_channels()
  end
end
