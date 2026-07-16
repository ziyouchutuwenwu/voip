defmodule Cmd do
  require Logger
  alias BeamFs.Lib.Connection

  def call(target, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    caller_id = Keyword.get(opts, :caller_id, "9999")
    domain = Keyword.get(opts, :domain) || domain!()
    channel = channel_str(target, domain)
    action = call_action(opts)
    args = "{origination_caller_id_number=#{caller_id}}#{channel} #{action}"
    Connection.bgapi("originate", args, timeout: timeout)
  end

  def ivr_call(target, opts \\ []) do
    play_file = opts[:play]
    say_text = opts[:say]
    dtmf_map = opts[:dtmf_map] || %{}
    transfer_to = opts[:transfer_to]
    timeout = Keyword.get(opts, :timeout, 60_000)
    caller_id = Keyword.get(opts, :caller_id, "9999")
    domain = Keyword.get(opts, :domain) || domain!()
    channel = channel_str(target, domain)

    action = if play_file, do: "&playback(#{play_file})&park()", else: "&park()"
    args = "{origination_caller_id_number=#{caller_id}}#{channel} #{action}"

    parent = self()

    spawn(fn ->
      BeamFs.Events.EventHandler.watch_any(:answer)
      send(parent, :ready)

      receive do
        {:answer, data} ->
          call_uuid = get_uuid(data)
          Logger.info("ivr: answered uuid=#{call_uuid}")
          if call_uuid do
            if say_text, do: say(call_uuid, say_text)

            if dtmf_map != %{} do
              ivr_dtmf_loop(call_uuid, dtmf_map, opts)
            else
              if transfer_to, do: transfer(call_uuid, transfer_to)
            end
          end
      after
        timeout -> Logger.warning("ivr: answer timeout")
      end
    end)

    receive do
      :ready -> :ok
    after
      5_000 -> :error
    end

    Connection.bgapi("originate", args, timeout: timeout)
  end

  def answer(uuid), do: Connection.api("uuid_answer", uuid)
  def hangup(uuid), do: Connection.api("uuid_kill", uuid)

  def play(uuid, file) do
    case Connection.api("uuid_play", "#{uuid} #{file}") do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end

  def say(uuid, text, opts \\ []) do
    engine = Keyword.get(opts, :engine, "flite")
    voice = Keyword.get(opts, :voice, "kal")
    case Connection.api("uuid_speak", "#{uuid} #{engine} #{voice} '#{text}'") do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
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

  defp ivr_dtmf_loop(uuid, dtmf_map, opts) do
    BeamFs.Events.EventHandler.watch(:dtmf, uuid)

    receive do
      {:dtmf, data} ->
        digit = dtmf_digit(data)

        case Map.get(dtmf_map, digit) do
          nil ->
            ivr_dtmf_loop(uuid, dtmf_map, opts)

          {:play, file} ->
            play(uuid, file)
            ivr_dtmf_loop(uuid, dtmf_map, opts)

          {:say, text} ->
            say(uuid, text)
            ivr_dtmf_loop(uuid, dtmf_map, opts)

          {:transfer, dest} ->
            transfer(uuid, dest)

          dest when is_binary(dest) ->
            transfer(uuid, dest)
        end
    after
      Keyword.get(opts, :dtmf_timeout, 60_000) -> :ok
    end
  end

  defp dtmf_digit(data) do
    case List.keyfind(data, "DTMF-Digit", 0) do
      {"DTMF-Digit", val} -> to_string(val)
      _ -> nil
    end
  end

  defp get_uuid(data) do
    case List.keyfind(data, "Unique-ID", 0) do
      {"Unique-ID", val} -> to_string(val)
      _ -> nil
    end
  end

  defp domain! do
    case Connection.api("global_getvar", "domain") do
      {:ok, d} when is_binary(d) -> String.trim(d)
      _ -> raise "failed to get domain from freeswitch"
    end
  end

  defp channel_str(target, domain) do
    if String.contains?(target, "/") or String.contains?(target, "@") do
      target
    else
      "user/#{target}@#{domain}"
    end
  end

  defp call_action(opts) do
    cond do
      play = opts[:play] -> "&playback(#{play})"
      say = opts[:say] -> "&speak(flite|kal|#{say})"
      true -> "&park()"
    end
  end
end
