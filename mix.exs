defmodule Elissh.Mixfile do
  use Mix.Project

  def project do
    [app: :elissh,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Elissh.Runner, name: :eli, emu_args: "-elixir ansi_enabled true -noinput"],
     deps: deps]
  end

  def application do
    [
      extra_applications: [:logger, :ssh, :yaml_elixir],
      mod: {Elissh, []}
    ]
  end

  defp deps do
    [
      {:sshex, "~> 2.2"},
      {:yaml_elixir, "~> 1.3"},
      {:io_tty, git: "https://github.com/swalker90/elixir-io_tty.git", tag: "v1.0.1"}
    ]
  end
end
