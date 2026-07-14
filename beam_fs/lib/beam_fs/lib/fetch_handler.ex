defmodule BeamFs.Lib.FetchHandler do
  require Logger

  @handlers %{
    dialplan: BeamFs.Events.Dialplan.Handler,
    directory: BeamFs.Events.Directory.Handler
  }

  def handle(section, tag, key, value, uuid) do
    section_atom = if is_atom(section), do: section, else: String.to_atom(section)

    result =
      case Map.get(@handlers, section_atom) do
        nil ->
          ""

        mod ->
          apply(mod, :fetch, [tag, key, value])
      end

    BeamFs.Lib.Connection.fetch_reply(uuid, result)
  rescue
    e ->
      Logger.error("fetch handler error: #{inspect(e)}")
      BeamFs.Lib.Connection.fetch_reply(uuid, "")
  end
end
