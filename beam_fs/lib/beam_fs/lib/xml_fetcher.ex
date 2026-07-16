defmodule BeamFs.Lib.XmlFetcher do
  require Logger

  @handlers %{
    dialplan: BeamFs.Events.Dialplan.Handler,
    directory: BeamFs.Events.Directory.Handler
  }

  def handle(node, section, tag, key, value, uuid, params \\ []) do
    section_atom = if is_atom(section), do: section, else: String.to_atom(section)

    result =
      case Map.get(@handlers, section_atom) do
        nil ->
          ""

        mod ->
          apply(mod, :fetch, [tag, key, value, params])
      end

    Logger.info(
      "fetch_reply to #{inspect(node)} uuid=#{inspect(uuid)} size=#{byte_size(result)}"
    )

    send({:fs, node}, {:fetch_reply, uuid, result})
    :ok
  rescue
    e ->
      Logger.error("fetch handler error: #{inspect(e)}")
      send({:fs, node}, {:fetch_reply, uuid, ""})
      :ok
  end
end
