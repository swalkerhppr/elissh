defmodule Elissh do

  @moduledoc """
    ./elissh -[cvmag] [host|group]
      A Utility to send a command to multiple hosts
      -c, --config      - config file
      -m, --command     - command to run
      -a, --all         - run command on all hosts(only the first if not specified)
      -u, --user        - remote user to run as on hosts
      -p, --password    - remote user password, if not supplied it assumes you are using keys
      -i, --interactive - interactive mode
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
    Elissh.CommandRunner.run_cmd({:spec, spec}, cmd, all)
  end

  def console(%{config: config_file, password: pass, user: user}, start \\ false) do
    if start do
      start_registries(config_file)
      Elissh.Console.start_link()
    end
    case Regex.named_captures(~r/(^!(?<intern>.+)$|^(?<extern>.+)$)/, IO.gets "eli>" ) do
      %{"intern" => con_com, "extern" => ""}  -> Elissh.Console.console_command(con_com)
      %{"intern" => "", "extern" => send_com} -> Elissh.Console.send_command(send_com)
    end
    console(%{config: config_file, password: pass, user: user})
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
    }
    {options, spec, _} = OptionParser.parse(args,
      switches: [
        config: :string,
        help: :boolean,
        cmd: :string,
        all: :boolean,
        password: :string,
        user: :string,
        interactive: :boolean
      ],
      aliases: [
        c: :config,
        h: :help,
        m: :cmd,
        a: :all,
        p: :password,
        u: :user,
        i: :interactive
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
