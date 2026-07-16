defmodule Cmd do
  alias BeamFs.Lib.Connection

  def call(target, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    caller_id = Keyword.get(opts, :caller_id, "9999")
    channel = channel_str(target, Keyword.get(opts, :domain) || domain!())
    action = call_action(opts)
    args = "{origination_caller_id_number=#{caller_id}}#{channel} #{action}"
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

  def ivr_call(target, opts \\ []) do
    {:ok, uuid} = call(target, Keyword.drop(opts, [:play, :say]))

    play_file = opts[:play]
    say_text = opts[:say]
    dtmf_map = opts[:dtmf_map] || %{}
    transfer_to = opts[:transfer_to]

    spawn(fn ->
      ivr_loop(uuid, play_file, say_text, dtmf_map, transfer_to, opts)
    end)

    {:ok, uuid}
  end

  defp ivr_loop(uuid, play_file, say_text, dtmf_map, transfer_to, opts) do
    BeamFs.Events.EventHandler.watch(:answer, uuid)

    receive do
      {:answer, _data} ->
        if play_file, do: play(uuid, play_file)
        if say_text, do: say(uuid, say_text)
    after
      Keyword.get(opts, :answer_timeout, 30_000) -> :ok
    end

    if dtmf_map != %{} do
      ivr_dtmf_loop(uuid, dtmf_map, opts)
    else
      if transfer_to, do: transfer(uuid, transfer_to)
    end
  end

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
