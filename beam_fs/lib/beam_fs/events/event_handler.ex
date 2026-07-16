defmodule BeamFs.Events.EventHandler do
  require Logger

  def handle_event(data) when is_list(data) do
    name = get_val(data, "Event-Name")
    subclass = get_val(data, "Event-Subclass")

    cond do
      name == "SOFIA_REGISTER" or (name == "CUSTOM" and subclass == "sofia::register") ->
        handle_register(data)
      name == "SOFIA_UNREGISTER" or (name == "CUSTOM" and subclass == "sofia::unregister") ->
        handle_unregister(data)
      name == "CHANNEL_CREATE" ->
        handle_channel_create(data)
      name == "CHANNEL_ANSWER" ->
        handle_channel_answer(data)
        notify_watcher(:answer, data)
      name == "CHANNEL_HANGUP" ->
        handle_channel_hangup(data)
      name == "CHANNEL_BRIDGE" ->
        handle_channel_bridge(data)
      name == "CHANNEL_DESTROY" ->
        handle_channel_destroy(data)
        notify_watcher(:hangup, data)

      name == "DTMF" ->
        notify_watcher(:dtmf, data)
      true ->
        Logger.debug("unhandled fs event: #{inspect(name)} subclass=#{inspect(subclass)}")
    end
  end

  defp get_val(data, key) do
    case List.keyfind(data, key, 0) do
      {^key, val} when is_binary(val) -> val
      {^key, val} when is_atom(val) -> Atom.to_string(val)
      _ -> nil
    end
  end

  defp get_str(data, key, default \\ "") do
    case List.keyfind(data, key, 0) do
      {^key, val} -> to_string(val)
      _ -> default
    end
  end

  defp handle_register(data) do
    user = get_str(data, "from-user")
    ip = get_str(data, "network-ip")
    Logger.info("sip register: #{user} from #{ip}")
  end

  defp handle_unregister(data) do
    user = get_str(data, "from-user")
    Logger.info("sip unregister: #{user}")
  end

  defp handle_channel_create(data) do
    uuid = get_str(data, "Unique-ID")
    caller = get_str(data, "Caller-Caller-ID-Number")
    dest = get_str(data, "Caller-Destination-Number")
    Logger.info("call create: #{caller} -> #{dest} [uuid=#{uuid}]")
  end

  defp handle_channel_answer(data) do
    uuid = get_str(data, "Unique-ID")
    Logger.info("call answer: #{uuid}")
  end

  defp handle_channel_hangup(data) do
    uuid = get_str(data, "Unique-ID")
    cause = get_str(data, "Hangup-Cause")
    Logger.info("call hangup: #{uuid} (#{cause})")
  end

  defp handle_channel_bridge(data) do
    a = get_str(data, "Bridge-A")
    b = get_str(data, "Bridge-B")
    Logger.info("bridged: #{a} <-> #{b}")
  end

  defp handle_channel_destroy(_data) do
    :ok
  end

  def watch(event, uuid) do
    Registry.register(BeamFs.EventRegistry, {event, uuid}, nil)
  end

  def watch_any(event) do
    Registry.register(BeamFs.EventRegistry, {event, :any}, nil)
  end

  defp notify_watcher(event, data) do
    uuid = get_str(data, "Unique-ID")
    key = {event, uuid}

    Registry.dispatch(BeamFs.EventRegistry, key, fn entries ->
      for {pid, _} <- entries do
        send(pid, {event, data})
      end
    end)

    Registry.dispatch(BeamFs.EventRegistry, {event, :any}, fn entries ->
      for {pid, _} <- entries do
        send(pid, {event, data})
      end
    end)
  end
end
