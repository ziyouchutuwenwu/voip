defmodule BeamFs.MixProject do
  use Mix.Project

  def project do
    [
      app: :beam_fs,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {BeamFsApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:xml_builder, "~> 2.1"},
      {:horde, "~> 0.4"},
      {:jason, "~> 1.4"}
    ]
  end
end
