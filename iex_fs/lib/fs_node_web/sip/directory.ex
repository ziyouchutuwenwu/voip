defmodule FsNodeWeb.Sip.Directory do
  import Ecto.Query
  alias FsNodeApp.Repo
  alias FsNodeApp.Sip.User
  alias FsNodeWeb.Sip.DirectoryXml

  def fetch(_tag, _key, value) do
    result =
      Repo.one(
        from u in User,
        where: u.username == ^value and u.enabled == true,
        limit: 1
      )

    case result do
      nil -> ""
      user -> DirectoryXml.user(user)
    end
  end
end
