defmodule OceanWave.MixProject do
  use Mix.Project

  def project do
    [
      app: :ocean_wave,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      target: System.get_env("MIX_TARGET") || :host
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OceanWave.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp releases do
    [
      ocean_wave: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end

  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.8"}
    ]
  end
end
