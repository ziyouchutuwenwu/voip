defmodule FsNodeApp.Sip.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "sip_users" do
    field :username, :string
    field :password, :string
    field :domain, :string
    field :enabled, :boolean, default: true
    field :caller_id_name, :string
    field :caller_id_number, :string
    field :vm_enabled, :boolean, default: false
    field :vm_password, :string
    field :description, :string

    timestamps()
  end

  def changeset(user, attrs) do
    default_domain = Application.get_env(:fs_node, :sip, [])[:default_domain]

    user
    |> cast(attrs, [:username, :password, :domain, :enabled, :caller_id_name, :caller_id_number, :vm_enabled, :vm_password, :description])
    |> validate_required([:username, :password])
    |> put_change_if_missing(:domain, default_domain)
    |> validate_required([:domain])
    |> unique_constraint(:username, name: :sip_users_username_domain_index)
  end

  defp put_change_if_missing(changeset, field, value) do
    if get_field(changeset, field) do
      changeset
    else
      put_change(changeset, field, value)
    end
  end

end
