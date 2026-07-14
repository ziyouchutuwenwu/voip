defmodule BeamFs.Horde.Registry do
  @name __MODULE__

  def child_spec(_opts) do
    %{
      id: @name,
      start: {Horde.Registry, :start_link, [[name: @name, keys: :unique, members: :auto]]},
      restart: :permanent,
      shutdown: 5_000,
      type: :supervisor
    }
  end

  def name, do: @name
end
