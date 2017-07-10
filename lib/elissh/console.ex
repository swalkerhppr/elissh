defmodule Elissh.Console do
  use GenServer

  defstruct cmds: [], specs: [], user: nil, pass: nil

  @command_char Application.get_env(:elissh, :command_char)

  @moduledoc """
    Anything without a #{@command_char} is added as a commmand to run
    #{@command_char}run_on <host|group> - add a host or group to the hosts to run on
    #{@command_char}user <username>     - set the remote username
    #{@command_char}password <pass>     - set the password for the remote user
    #{@command_char}connect             - connect to hosts to run on
    #{@command_char}send                - run commands on hosts
  """

  @doc "Start the console"
  def start_link do
    GenServer.start_link(__MODULE__, %Elissh.Console{}, name: Console)
  end

  @doc "Apply a console command to change the console state"
  def console_command(command), do: GenServer.call(Console, {:console, parse_console_command(command)})

  @doc "Add a command to send to hosts" 
  def send_command(command), do: GenServer.call(Console, {:add, command})

  def parse_console_command(command) do
    command 
    |> String.split(" ") 
    |> List.to_tuple 
    |> case do
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


  def init(map) do
    {:ok, map}
  end

  def handle_call({:console, {:user, user}}, _from, map), do: {:reply, :ok, %{map | user: user}}
  def handle_call({:console, {:pass, password}}, _from, map), do: {:reply, :ok, %{map | pass: password}}
  def handle_call({:console, {:spec, :reset}}, _from, map), do: {:reply, :ok, %{map| specs: []}}
  def handle_call({:console, :exit}, _from, _), do: System.halt(0)

  def handle_call({:console, :help}, _from, map) do
    IOTty.puts @moduledoc
    {:reply, :ok, map}
  end

  def handle_call({:console, :info}, _from, map) do
    map |> inspect |> IOTty.puts
    {:reply, :ok, map}
  end

  def handle_call({:console, {:spec, hostspec}}, _from, map) do
    specs = Elissh.ConfigRegistry.get({:spec, hostspec})
    {:reply, :ok, Map.update!(map, :specs, &(&1++[specs])) }
  end

  def handle_call({:console, :connect}, _from, map = %{user: user, pass: pass, specs: specs}) do
    Elissh.ConnectionRegistry.set_user({user, pass})
    {:reply, Enum.map(specs, &Elissh.ConnectionRegistry.connect(&1)), map}
  end

  def handle_call({:console, :send}, _from, map = %{cmds: cmds, specs: specs}) do
    {:reply,
      Enum.map(specs, fn spec -> Enum.map(Enum.reverse(cmds), &Elissh.ConnectionRegistry.run(spec, &1)) end), 
      %{map | cmds: []}
    }
  end

  def handle_call({:add, command}, _from, map), do: {:reply, :ok, Map.update!(map, :cmds, &([command | &1])) }

end
