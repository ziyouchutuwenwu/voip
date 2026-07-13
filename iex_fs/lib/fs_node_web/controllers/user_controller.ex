defmodule FsNodeWeb.UserController do
  use Phoenix.Controller, formats: [:json]

  alias FsNodeApp.Repo
  alias FsNodeApp.Sip.User

  plug :put_view, FsNodeWeb.UserView

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, :index, users: users)
  end

  def create(conn, params) do
    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:show, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil -> send_resp(conn, 404, "not found")
      user -> render(conn, :show, user: user)
    end
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(User, id) do
      nil -> send_resp(conn, 404, "not found")
      user ->
        changeset = User.changeset(user, params)
        case Repo.update(changeset) do
          {:ok, user} ->
            render(conn, :show, user: user)
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> render(:error, changeset: changeset)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil -> send_resp(conn, 404, "not found")
      user ->
        Repo.delete(user)
        send_resp(conn, 204, "")
    end
  end
end
