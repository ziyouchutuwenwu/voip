defmodule FsNode do
  alias FsNode.Lib.Connection

  defdelegate api(cmd, args \\ ""), to: Connection
  defdelegate bgapi(cmd, args \\ "", opts \\ []), to: Connection
  defdelegate connected?(), to: Connection
end
