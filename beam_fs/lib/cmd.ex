defmodule Cmd do
  @cache_key {:cmd, :domain}

  alias BeamFs.Lib.Connection

  def call(target, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    caller_id = Keyword.get(opts, :caller_id, "9999")
    channel = channel_str(target, Keyword.get(opts, :domain) || domain!())
    args = "{origination_caller_id_number=#{caller_id}}#{channel} &park()"
    Connection.bgapi("originate", args, timeout: timeout)
  end

  def answer(uuid), do: Connection.api("uuid_answer", uuid)
  def hangup(uuid), do: Connection.api("uuid_kill", uuid)

  def play(uuid, file) do
    {:ok, _} = Connection.api("uuid_play", "#{uuid} #{file}")
    :ok
  end

  def say(uuid, text, opts \\ []) do
    engine = Keyword.get(opts, :engine, "flite")
    voice = Keyword.get(opts, :voice, "kal")
    {:ok, _} = Connection.api("uuid_speak", "#{uuid} #{engine} #{voice} '#{text}'")
    :ok
  end

  def record(uuid, file) do
    {:ok, _} = Connection.api("uuid_record", "#{uuid} start #{file}")
    :ok
  end

  def stop_record(uuid) do
    {:ok, _} = Connection.api("uuid_record", "#{uuid} stop")
    :ok
  end

  def dtmf(uuid, digits) do
    {:ok, _} = Connection.api("uuid_send_dtmf", "#{uuid} #{digits}")
    :ok
  end

  def transfer(uuid, dest, opts \\ []) do
    dialplan = Keyword.get(opts, :dialplan, "xml")
    context = Keyword.get(opts, :context, "default")
    args = [uuid, "-both", dest, dialplan, context] |> Enum.join(" ")
    Connection.api("transfer", args)
  end

  def bridge(uuid1, uuid2), do: Connection.api("uuid_bridge", "#{uuid1} #{uuid2}")

  def channels, do: Connection.api("show", "channels")
  def registrations, do: Connection.api("show", "registrations")

  defp domain! do
    case :persistent_term.get(@cache_key, nil) do
      nil -> fetch_and_cache!()
      d -> d
    end
  end

  defp fetch_and_cache! do
    case Connection.api("global_getvar", "domain") do
      {:ok, d} when is_binary(d) ->
        d = String.trim(d)
        :persistent_term.put(@cache_key, d)
        d
      _ ->
        raise "failed to get domain from FreeSWITCH"
    end
  end

  defp channel_str(target, domain) do
    if String.contains?(target, "/") or String.contains?(target, "@") do
      target
    else
      "user/#{target}@#{domain}"
    end
  end
end
