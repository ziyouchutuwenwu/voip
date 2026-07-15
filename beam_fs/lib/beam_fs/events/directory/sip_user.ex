defmodule BeamFs.SipUser do
  def list_all do
    BeamFs.Config.Fetcher.sip_users()
  end

  def find_by_username(username) when is_binary(username) do
    BeamFs.Config.Fetcher.sip_users()
    |> Enum.find(fn u -> u[:username] == username end)
  end
end
