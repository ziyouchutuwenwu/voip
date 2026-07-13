defmodule FsNodeWeb do
  def controller do
    quote do
      import Phoenix.Controller, only: [json: 2, render: 3, html: 2, text: 2, put_view: 2]
      import Plug.Conn, only: [halt: 1]
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/fs_node_web/templates"
    end
  end

  def __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
