defmodule FsNodeWeb.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", FsNodeWeb do
    pipe_through :api

    get "/status", StatusController, :index

    get "/users", UserController, :index
    post "/users", UserController, :create
    get "/users/:id", UserController, :show
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
  end

  scope "/api/calls", FsNodeWeb do
    get "/", CallController, :index
    post "/", CallController, :create
    delete "/:uuid", CallController, :delete
  end

  scope "/api/fetch", FsNodeWeb do
    post "/directory", FetchController, :directory
  end
end
