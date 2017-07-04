defmodule Elissh.Console do
  use GenServer
  @command_char Application.get_env(:elissh, :command_char)

  @moduledoc """
    Anything without a #{@command_char} is added as a commmand to run
    #{@command_char}run_on <host|group> - add a host or group to the hosts to run on
    #{@command_char}user <username>     - set the remote username
    #{@command_char}password <pass>     - set the password for the remote user
    #{@command_char}connect             - connect to hosts to run on
    #{@command_char}send                - run commands on hosts
  """

  def start_link do
    GenServer.start_link(__MODULE__, %{:cmds => [], :specs => [], :user => nil, :pass => nil }, name: Console)
  end

  def console_command(command) do
    GenServer.call(Console, {:console, parse_command(command)})
  end

  def parse_command(command) do
    case List.to_tuple(String.split(command, " ")) do
      {"run_on", spec}   -> {:spec, spec} 
      {"reset"}          -> {:spec, :reset} 
      {"user", user}     -> {:user, user}
      {"password", pass} -> {:pass, pass}
      {"connect"}        -> :connect
      {"send"}           -> :send
      {"info"}           -> :info
      {"help"}           -> :help
      {"exit"}           -> :exit
      _                  -> :help
    end
  end

  def send_command(command) do
    GenServer.call(Console, {:add, command})
  end

  def init(map) do
    {:ok, map}
  end

  def handle_call({:add, command}, _from, map) do
    {:reply, :ok, Map.update!(map, :cmds, fn l -> [command | l] end) }
  end

  def handle_call({:console, :help}, _from, map) do
    IO.puts @moduledoc
    {:reply, :ok, map}
  end

  def handle_call({:console, :info}, _from, map) do
    IO.puts inspect map
    {:reply, :ok, map}
  end

  def handle_call({:console, {:user, user}}, _from, map) do
    {:reply, :ok, %{map | user: user}}
  end

  def handle_call({:console, {:pass, password}}, _from, map) do
    {:reply, :ok, %{map | pass: password}}
  end

  def handle_call({:console, {:spec, :reset}}, _from, map) do
    {:reply, :ok, %{map| specs: []}}
  end

  def handle_call({:console, {:spec, hostspec}}, _from, map) do
    specs = Elissh.ConfigRegistry.get({:spec, hostspec})
    {:reply, :ok, Map.update!(map, :specs, fn l -> [specs] ++ l end) }
  end

  def handle_call({:console, :connect}, _from, map) do
    Elissh.ConnectionRegistry.set_user({map[:user], map[:pass]})
    {:reply, Enum.map(map[:specs], &Elissh.ConnectionRegistry.connect(&1)), map}
  end

  def handle_call({:console, :send}, _from, map) do
    {:reply,
      Enum.map(map[:specs], fn spec -> Enum.map(Enum.reverse(map[:cmds]), &Elissh.ConnectionRegistry.run(spec, &1)) end), 
      %{map | cmds: []}
    }
  end

  def handle_call({:console, :exit}, _from, _) do
    System.halt(0)
  end
end
