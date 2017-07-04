defmodule Elissh.CommandRunner do
  @doc """
    Run a command on a (set of) host(s)
  """
  def run_cmd(lookup, cmd, false) do
    host = case Elissh.ConfigRegistry.get(lookup) do
      {:multiple, hosts} -> hd(hosts)
      {:single, host} -> host
    end
    Elissh.ConnectionRegistry.connect({:single, host})
    task = Task.async( fn -> Elissh.ConnectionRegistry.run({:single, host}, cmd) end )
    Task.await(task)
  end 

  def run_cmd(lookup, cmd, true) do
    hosts = Elissh.ConfigRegistry.get(lookup)
    Elissh.ConnectionRegistry.connect(hosts)
    task = Task.async( fn -> Elissh.ConnectionRegistry.run(hosts, cmd) end )
    Task.await(task)
  end 
end
