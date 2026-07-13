defmodule FsNode.Events.Cdr.Manager do
  alias FsNodeApp.Repo
  alias FsNode.Events.Cdr

  def create_from_event(data) when is_list(data) do
    %Cdr{}
    |> Cdr.changeset(%{
      uuid: data[:"Unique-ID"],
      caller: data[:"Caller-Caller-ID-Number"],
      destination: data[:"Caller-Destination-Number"],
      direction: data[:"Caller-Direction"],
      state: "created",
      started_at: parse_datetime(data[:"Caller-Channel-Created-Time"])
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: :uuid)
  end

  def answer(data) when is_list(data) do
    uuid = data[:"Unique-ID"]

    Repo.get_by(Cdr, uuid: uuid)
    |> case do
      nil -> :ok
      cdr ->
        cdr
        |> Ecto.Changeset.change(%{
          state: "answered",
          answered_at: parse_datetime(data[:"Answer-Time"]) || DateTime.utc_now()
        })
        |> Repo.update()
    end
  end

  def hangup(data) when is_list(data) do
    uuid = data[:"Unique-ID"]

    Repo.get_by(Cdr, uuid: uuid)
    |> case do
      nil -> :ok
      cdr ->
        started = cdr.started_at || parse_datetime(data[:"Caller-Channel-Created-Time"])
        now = DateTime.utc_now()

        cdr
        |> Ecto.Changeset.change(%{
          state: "hangup",
          hangup_cause: data[:"Hangup-Cause"],
          ended_at: now,
          duration: if(started, do: DateTime.diff(now, started, :second), else: 0)
        })
        |> Repo.update()
    end
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil

  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
end
