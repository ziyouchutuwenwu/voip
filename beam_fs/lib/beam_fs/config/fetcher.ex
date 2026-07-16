defmodule BeamFs.Config.Fetcher do
  @freeswitch_key :freeswitch
  @sip_key :sip

  def fs_node do
    Application.get_env(:beam_fs, @freeswitch_key, [])[:node] ||
      raise "missing :node in freeswitch config"
  end

  def sip_users do
    Application.get_env(:beam_fs, @sip_key, [])[:users] || []
  end
end
