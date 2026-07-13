defmodule FsNodeWeb.UserView do
  use FsNodeWeb, :view

  def render("index.json", %{users: users}) do
    %{users: Enum.map(users, &user_json/1)}
  end

  def render("show.json", %{user: user}) do
    %{user: user_json(user)}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  defp user_json(user) do
    %{
      id: user.id,
      username: user.username,
      domain: user.domain,
      enabled: user.enabled,
      caller_id_name: user.caller_id_name,
      caller_id_number: user.caller_id_number,
      vm_enabled: user.vm_enabled,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
