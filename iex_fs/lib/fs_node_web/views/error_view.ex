defmodule FsNodeWeb.ErrorView do
  use FsNodeWeb, :view

  def render("500.json", _assigns) do
    %{error: "internal server error"}
  end

  def render("404.json", _assigns) do
    %{error: "not found"}
  end
end
