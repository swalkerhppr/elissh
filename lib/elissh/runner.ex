defmodule Elissh.Runner do

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
      if config.script, do: Elissh.start_script_reader(Elissh.Supervisor, config.script)
    end

    case Regex.named_captures(~r/(^#{@command_char}(?<intern>.+)$|^(?<extern>.+)$)/, prompt_or_get_script(config.script)) do
      %{"intern" => con_com, "extern" => ""}  -> Elissh.Console.console_command(con_com)
      %{"intern" => "", "extern" => send_com} -> Elissh.Console.send_command(send_com)
      nil -> nil
    end |> inspect |> IO.puts

    console(config)
  end

  defp prompt_or_get_script(script) do
    case script do
      false -> IO.gets "eli>"
      _ -> Elissh.ScriptReader.next()
    end
  end

  def start_registries(config_file, fact_file) do
    Elissh.start_config_registry(Elissh.Supervisor, config_file)
    Elissh.start_fact_registry(Elissh.Supervisor, fact_file)
  end

  defp parse_args(args) do
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
