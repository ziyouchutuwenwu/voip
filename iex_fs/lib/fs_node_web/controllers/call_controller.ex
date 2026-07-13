defmodule FsNodeWeb.CallController do
  use Phoenix.Controller, formats: [:json]

  alias FsNode.Lib.Connection

  def index(conn, _params) do
    case Connection.api("show", "channels") do
      {:ok, result} ->
        lines = String.split(result, "\n")
        calls =
          lines
          |> Enum.filter(&String.contains?(&1, "sofia/"))
          |> Enum.map(fn line ->
            parts = String.split(line, ",")
            %{
              uuid: Enum.at(parts, 0, ""),
              direction: Enum.at(parts, 1, ""),
              name: Enum.at(parts, 4, ""),
              state: Enum.at(parts, 5, ""),
              caller: Enum.at(parts, 7, ""),
              dest: Enum.at(parts, 9, ""),
              application: Enum.at(parts, 10, ""),
              callstate: Enum.at(parts, 25, "")
            }
          end)

        json(conn, %{calls: calls})

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end

  def create(conn, %{"from" => from, "to" => to}) do
    case FsNode.Events.Call.Manager.originate(from, to) do
      {:ok, result} ->
        json(conn, %{status: "ok", result: result})

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end

  def create(conn, _params) do
    json(conn, %{error: "missing 'from' or 'to' parameter"})
  end

  def delete(conn, %{"uuid" => uuid}) do
    case FsNode.Events.Call.Manager.hangup(uuid) do
      {:ok, result} ->
        json(conn, %{status: "ok", result: result})

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end
end
