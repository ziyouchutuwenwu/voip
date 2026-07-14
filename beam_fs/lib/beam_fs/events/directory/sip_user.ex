defmodule BeamFs.SipUser do
  @moduledoc """
  用户 CRUD 抽象层。
  当前从 config 读取，后续替换为 Ecto 时只需修改本模块内部实现。
  """

  def list_all do
    config(:users, [])
  end

  def find_by_username(username) when is_binary(username) do
    config(:users, [])
    |> Enum.find(fn u -> u[:username] == username end)
  end

  defp config(key, default) do
    Application.get_env(:beam_fs, :sip, [])[key] || default
  end
end
