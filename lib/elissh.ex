defmodule Elissh do

  @command_char Application.get_env(:elissh, :command_char)

  @moduledoc """
    ./elissh [options] [host|group]
      A Utility to send a command to multiple hosts
      -c, --config      - config file
      -f, --facts       - facts file
      -m, --command     - command to run
      -a, --all         - run command on all hosts(only the first if not specified)
      -u, --user        - remote user to run as on hosts
      -p, --password    - remote user password, if not supplied it assumes you are using keys
      -i, --interactive - interactive mode
      -s, --script      - interactive mode script to run
  """

  def main(args) do
    parsed = parse_args(args)
    case parsed do
      %{interactive: true} -> console(parsed, true)
      {_ , _}              -> push(parsed)
      _                    -> IO.puts @moduledoc
    end
  end

  def push({config = %DefaultConfig{}, spec}) do
    start_registries(config.config_file, config.facts_file)
    Elissh.ConnectionRegistry.set_user({config.user, config.pass})
    Elissh.CommandRunner.run_cmd({:spec, spec}, config.cmd, config.all) |> inspect |> IO.puts
  end

  def console(config = %DefaultConfig{}, start \\ false) do
    if start do
      start_registries(config.config_file, config.facts_file)
      Elissh.Console.start_link()
      if config.script, do: Elissh.FileReader.start_link(config.script)
    end

    case Regex.named_captures(~r/(^#{@command_char}(?<intern>.+)$|^(?<extern>.+)$)/, prompt_or_get_script(config.script)) do
      %{"intern" => con_com, "extern" => ""}  -> Elissh.Console.console_command(con_com)
      %{"intern" => "", "extern" => send_com} -> Elissh.Console.send_command(send_com)
      nil -> nil
    end |> inspect |> IO.puts

    console(config)
  end

  def prompt_or_get_script(script) do
    case script do
      false -> IO.gets "eli>"
      _ -> Elissh.FileReader.next()
    end
  end

  def start_registries(config_file, facts_file) do
    config_file |> File.read! |> YamlElixir.read_from_string |> Elissh.ConfigRegistry.start_link
    facts_file |> File.read! |> YamlElixir.read_from_string |> Elissh.FactRegistry.start_link
    Elissh.ConnectionRegistry.start_link()
  end

  def parse_args(args) do
    default_opts = %DefaultConfig{}
    {options, spec, _} = OptionParser.parse(args,
      switches: [
        config: :string,
        help: :boolean,
        cmd: :string,
        all: :boolean,
        password: :string,
        user: :string,
        interactive: :boolean,
        script: :string,
        facts: :string,
      ],
      aliases: [
        c: :config,
        h: :help,
        m: :cmd,
        a: :all,
        p: :password,
        u: :user,
        i: :interactive,
        s: :script,
        f: :facts,
      ],
    )

    case result_conf = Enum.into(options, default_opts) do
      %{help: true}       -> :help
      %{interactive: true} -> result_conf
      %{cmd: _}           -> {result_conf, hd(spec)}
       _                  -> :help
    end
  end
end
