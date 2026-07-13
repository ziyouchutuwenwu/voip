defmodule FsNode.Lib.API do
  alias FsNode.Lib.Connection

  def version, do: api("version")
  def show_calls, do: api("show", "calls")
  def show_channels, do: api("show", "channels")
  def show_gateways, do: api("show", "gateways")
  def show_registrations, do: api("show", "registrations")
  def status, do: api("status")

  def originate(from, to, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    domain = opts[:domain] || Application.get_env(:fs_node, :sip)[:default_domain]
    channel = if String.contains?(to, "/") or String.contains?(to, "@"), do: to, else: "user/#{to}@#{domain}"
    args = "{origination_caller_id_number=#{from}}#{channel} &park()"
    bgapi("originate", args, timeout: timeout)
  end

  def hangup(uuid), do: api("uuid_kill", uuid)

  def transfer(uuid, dest, opts \\ []) do
    args = [uuid, "-both", dest, Keyword.get(opts, :dialplan, "XML"), Keyword.get(opts, :context, "default")]
    api("transfer", Enum.join(args, " "))
  end

  def bridge(uuid1, uuid2), do: api("uuid_bridge", "#{uuid1} #{uuid2}")

  def api(command, args \\ ""), do: Connection.api(command, args)
  def bgapi(command, args \\ "", opts \\ []), do: Connection.bgapi(command, args, opts)
end
