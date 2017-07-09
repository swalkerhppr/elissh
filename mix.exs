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

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      extra_applications: [:logger, :ssh, :yaml_elixir],
      mod: {Elissh, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:sshex, "~> 2.2"}, {:yaml_elixir, "~> 1.3"},{:io_tty, git: "https://github.com/swalker90/elixir-io_tty.git"}]
  end
end
