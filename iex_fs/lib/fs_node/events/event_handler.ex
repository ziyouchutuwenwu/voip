defmodule FsNode.Events.EventHandler do
  require Logger

  @topic "freeswitch:events"

  def handle_event(data) when is_list(data) do
    name = data[:"Event-Name"]

    broadcast(name, data)

    case name do
      :SOFIA_REGISTER -> handle_register(data)
      :SOFIA_UNREGISTER -> handle_unregister(data)
      :CHANNEL_CREATE -> handle_channel_create(data)
      :CHANNEL_ANSWER -> handle_channel_answer(data)
      :CHANNEL_HANGUP -> handle_channel_hangup(data)
      :CHANNEL_BRIDGE -> handle_channel_bridge(data)
      :CHANNEL_DESTROY -> handle_channel_destroy(data)
      _ -> Logger.debug("Unhandled FS event: #{name}")
    end
  end

  defp handle_register(data) do
    user = data[:"Caller-Caller-ID-Number"]
    ip = data[:"Caller-Network-Addr"]
    Logger.info("SIP register: #{user} from #{ip}")
  end

  defp handle_unregister(data) do
    user = data[:"Caller-Caller-ID-Number"]
    Logger.info("SIP unregister: #{user}")
  end

  defp handle_channel_create(data) do
    uuid = data[:"Unique-ID"]
    caller = data[:"Caller-Caller-ID-Number"]
    dest = data[:"Caller-Destination-Number"]
    Logger.info("Call create: #{caller} -> #{dest} [uuid=#{uuid}]")

    FsNode.Events.Cdr.Manager.create_from_event(data)
  end

  defp handle_channel_answer(data) do
    Logger.info("Call answer: #{data[:"Unique-ID"]}")
    FsNode.Events.Cdr.Manager.answer(data)
  end

  defp handle_channel_hangup(data) do
    uuid = data[:"Unique-ID"]
    cause = data[:"Hangup-Cause"]
    Logger.info("Call hangup: #{uuid} (#{cause})")
    FsNode.Events.Cdr.Manager.hangup(data)
  end

  defp handle_channel_bridge(data) do
    Logger.info("Bridged: #{data[:"Bridge-A"]} <-> #{data[:"Bridge-B"]}")
  end

  defp handle_channel_destroy(_data) do
    :ok
  end

  defp broadcast(name, data) do
    Phoenix.PubSub.broadcast(
      FsNode.PubSub,
      @topic,
      {:freeswitch_event, name, data}
    )
  end
end
