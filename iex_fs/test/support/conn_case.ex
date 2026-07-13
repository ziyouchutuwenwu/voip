defmodule FsNodeWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest

      @endpoint FsNodeWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, _} = Application.ensure_all_started(:fs_node)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
