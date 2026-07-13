defmodule FsNode.Repo.Migrations.CreateSipUsers do
  use Ecto.Migration

  def change do
    create table(:sip_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :password, :string, null: false
      add :domain, :string, null: false, default: "192.168.88.20"
      add :enabled, :boolean, default: true
      add :caller_id_name, :string
      add :caller_id_number, :string
      add :vm_enabled, :boolean, default: false
      add :vm_password, :string
      add :description, :string

      timestamps()
    end

    create unique_index(:sip_users, [:username, :domain], name: :sip_users_username_domain_index)
    create index(:sip_users, [:domain])
  end
end
