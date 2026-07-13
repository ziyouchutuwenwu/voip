defmodule FsNodeWeb.FetchController do
  use Phoenix.Controller, formats: [:html]

  plug :put_resp_content_type, "text/xml"

  alias FsNodeWeb.Sip.DirectoryXml

  def directory(conn, params) do
    xml =
      cond do
        params["purpose"] == "network-list" ->
          DirectoryXml.network_list()

        params["user"] && params["user"] != "" ->
          username = params["user"]
          domain = params["domain"] || ""

          DirectoryXml.user(username, domain, params["password"] || "")

        params["tag_name"] == "domain" ->
          DirectoryXml.domain(params["key_value"] || params["domain"] || "")

        true ->
          ""
      end

    send_resp(conn, 200, xml)
  end
end
