defmodule FsNodeWeb.StatusControllerTest do
  use FsNodeWeb.ConnCase

  test "GET /api/status returns JSON", %{conn: conn} do
    conn = get(conn, "/api/status")
    assert json_response(conn, 200)["connected"] == false
    assert json_response(conn, 200)["freeswitch_version"] == nil
  end
end
