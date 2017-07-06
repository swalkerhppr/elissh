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
    Elissh.ConnectionRegistry.run({:single, host}, cmd)
  end 

  def run_cmd(lookup, cmd, true) do
    hosts = Elissh.ConfigRegistry.get(lookup)
    Elissh.ConnectionRegistry.connect(hosts)
    Elissh.ConnectionRegistry.run(hosts, cmd)
  end 
end
