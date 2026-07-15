defmodule BeamFs.Config.Fetcher do
  @freeswitch_key :freeswitch
  @sip_key :sip

  def fs_nodes do
    config =
      Application.get_env(:beam_fs, @freeswitch_key) ||
        raise "missing config :beam_fs, :freeswitch"

    %{
      nodes: config[:nodes] || raise("missing :nodes in freeswitch config")
    }
  end

  def sip_users do
    Application.get_env(:beam_fs, @sip_key, [])[:users] || []
  end
end
