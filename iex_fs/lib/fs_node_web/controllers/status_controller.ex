defmodule FsNodeWeb.StatusController do
  use Phoenix.Controller, formats: [:json]

  alias FsNode.Lib.Connection

  def index(conn, _params) do
    connected = Connection.connected?()

    {freeswitch_version, freeswitch_node} =
      if connected do
        case Connection.api("version") do
          {:ok, v} -> {v, Connection.freeswitch_node()}
          _ -> {nil, nil}
        end
      else
        {nil, nil}
      end

    json(conn, %{
      connected: connected,
      freeswitch_node: freeswitch_node,
      freeswitch_version: freeswitch_version
    })
  end
end
