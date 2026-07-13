defmodule FsNode.Repo.Migrations.CreateCdrs do
  use Ecto.Migration

  def change do
    create table(:cdrs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uuid, :string, null: false
      add :caller, :string
      add :destination, :string
      add :direction, :string
      add :state, :string
      add :hangup_cause, :string
      add :started_at, :utc_datetime_usec
      add :answered_at, :utc_datetime_usec
      add :ended_at, :utc_datetime_usec
      add :duration, :integer

      timestamps()
    end

    create unique_index(:cdrs, [:uuid])
    create index(:cdrs, [:started_at])
  end
end
