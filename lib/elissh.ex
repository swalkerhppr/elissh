defmodule Elissh do

  @command_char Application.get_env(:elissh, :command_char)

  @moduledoc """
    ./elissh [options] [host|group]
      A Utility to send a command to multiple hosts
      -c, --config      - config file
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

  def push({%{config: config_file, cmd: cmd, all: all, password: pass, user: user}, spec}) do
    start_registries(config_file)
    Elissh.ConnectionRegistry.set_user({user, pass})
    IO.puts inspect Elissh.CommandRunner.run_cmd({:spec, spec}, cmd, all)
  end

  def console(%{config: config_file, password: pass, user: user, script: script}, start \\ false) do
    if start do
      start_registries(config_file)
      Elissh.Console.start_link()
      if script, do: Elissh.FileReader.start_link(script)
    end
    case Regex.named_captures(~r/(^#{@command_char}(?<intern>.+)$|^(?<extern>.+)$)/, prompt_or_get_script(script)) do
      %{"intern" => con_com, "extern" => ""}  -> IO.puts(inspect Elissh.Console.console_command(con_com))
      %{"intern" => "", "extern" => send_com} -> IO.puts(inspect Elissh.Console.send_command(send_com))
      nil -> nil
    end
    console(%{config: config_file, password: pass, user: user, script: script})
  end

  def prompt_or_get_script(script) do
    case script do
      false -> IO.gets "eli>"
      _ -> Elissh.FileReader.next()
    end
  end

  def start_registries(config_file) do
    {:ok, yaml_config} = File.read(config_file)
    config = YamlElixir.read_from_string yaml_config
    Elissh.ConfigRegistry.start_link(config)
    Elissh.ConnectionRegistry.start_link()
  end

  def parse_args(args) do
    default_opts = %{
      config:  "./hosts.yml",
      all: false,
      password: nil,
      user: System.get_env("USERNAME"),
      interactive: false,
      script: false
    }
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
      ],
      aliases: [
        c: :config,
        h: :help,
        m: :cmd,
        a: :all,
        p: :password,
        u: :user,
        i: :interactive,
        s: :script
      ],
    )
    result_conf = Enum.into(options, default_opts)
    case result_conf do
      %{help: true}       -> :help
      %{interactive: true} -> result_conf
      %{cmd: _}           -> {result_conf, hd(spec)}
       _                  -> :help
    end
  end
end
