defmodule BeamFs.Events.Call.Manager do
  alias BeamFs.Lib.Connection

  def originate(from, to, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    domain = opts[:domain]
    channel = if String.contains?(to, "/") or String.contains?(to, "@"), do: to, else: "user/#{to}@#{domain || raise ArgumentError, "missing :domain in opts for originate to=#{to}"}"
    args = "{origination_caller_id_number=#{from}}#{channel} &park()"
    Connection.bgapi("originate", args, timeout: timeout)
  end

  def hangup(uuid), do: Connection.api("uuid_kill", uuid)

  def transfer(uuid, dest, opts \\ []) do
    args = [uuid, "-both", dest, Keyword.get(opts, :dialplan, "xml"), Keyword.get(opts, :context, "default")]
    Connection.api("transfer", Enum.join(args, " "))
  end

  def bridge(u1, u2), do: Connection.api("uuid_bridge", "#{u1} #{u2}")

  def list_active, do: Connection.api("show", "calls")
end
