defmodule BeamFs.Horde.Supervisor do
  @name __MODULE__

  def child_spec(_opts) do
    %{
      id: @name,
      start:
        {Horde.DynamicSupervisor, :start_link,
         [[name: @name, strategy: :one_for_one, members: :auto]]},
      restart: :permanent,
      shutdown: 5_000,
      type: :supervisor
    }
  end

  def name, do: @name
end
