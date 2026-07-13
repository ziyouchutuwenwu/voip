defmodule FsNode.Lib.FetchHandler do
  @handlers %{
    dialplan: FsNode.Events.Dialplan.Handler
  }

  def handle(section, tag, key, value, uuid) do
    section_atom = if is_atom(section), do: section, else: String.to_atom(section)

    case Map.get(@handlers, section_atom) do
      nil ->
        FsNode.Lib.Connection.fetch_reply(uuid, "")

      mod ->
        result = apply(mod, :fetch, [tag, key, value])
        FsNode.Lib.Connection.fetch_reply(uuid, result)
    end
  end
end
