defmodule Elissh.ConnectionRegistry do
  use GenServer

  @sshmodule Application.get_env(:elissh, :sshmodule)

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: Connections)
  end 

  @doc """
    Set the user for all of the connections
  """
  def set_user(user) do
    GenServer.call(Connections, {:user, user}) 
  end

  @doc """
    Connect to a single host 
  """
  def connect({:single, host}) do
    GenServer.call(Connections, {:connect, host}) 
  end

  @doc """
    Connect to multiple hosts
  """
  def connect({:multiple, hosts}) do
    Enum.map hosts, &GenServer.call(Connections, {:connect, &1}) 
  end
  
  @doc """
    Run a command on a single host
  """
  def run({:single, host}, cmd) do
    GenServer.call(Connections, {:run, {host, cmd}})
  end

  @doc """
    Run a command on multiple hosts
  """
  def run({:multiple, hosts}, cmd) do
    Enum.map hosts, &GenServer.call(Connections, {:run, {&1, cmd}})
  end

  def init(%{}) do
    {:ok, %{}}
  end

  def handle_call({:user, {user, password}}, _from, map) do
    {:reply, :ok, Map.merge(map, %{user: user, password: password})}
  end 

  def handle_call({:connect, {_, ipaddress}}, _from, map) do
    args = case {ipaddress, map[:user], map[:password]} do
      {ip, user, nil} ->  [ip: ip, user: user, ssh_module: @sshmodule]
      {ip, user, pass} ->  [ip: ip , user: user, password: pass, ssh_module: @sshmodule]
    end
    case SSHEx.connect args do
      {:ok, conn} -> {:reply, :ok, Map.put(map, ipaddress, conn)}
      {:error, message} -> {:reply, {:error, message} , map}
    end
  end

  def handle_call({:run, {{hostname, ipaddress}, cmd}}, _from, map) do
    computed_cmd = Elissh.FactRegistry.replace_facts({hostname, ipaddress}, cmd)
    response = case Map.fetch(map, ipaddress) do
      {:ok, conn} -> SSHEx.run(conn, computed_cmd)
      :error -> {:error, "Not connected"}
    end
    case response do
      {:ok, message, 0} -> {:reply, {hostname, {:ok, Elissh.FactRegistry.extract_facts({hostname, ipaddress}, cmd, message)}}, map} 
      {:ok, message, status} -> {:reply, {hostname, {:error, message, :status, status}}, map} 
      {:error, message} -> {:reply, {hostname, {:error, message}}, map} 
    end
  end
end
