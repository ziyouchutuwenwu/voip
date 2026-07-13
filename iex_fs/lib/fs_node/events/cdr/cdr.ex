defmodule FsNode.Events.Cdr do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "cdrs" do
    field :uuid, :string
    field :caller, :string
    field :destination, :string
    field :direction, :string
    field :state, :string
    field :hangup_cause, :string
    field :started_at, :utc_datetime_usec
    field :answered_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
    field :duration, :integer

    timestamps()
  end

  def changeset(cdr, attrs) do
    cdr
    |> cast(attrs, [:uuid, :caller, :destination, :direction, :state, :hangup_cause,
                    :started_at, :answered_at, :ended_at, :duration])
    |> validate_required([:uuid])
    |> unique_constraint(:uuid)
  end
end
