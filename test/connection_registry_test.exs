defmodule Elissh.ConnectionRegistryTest do
  use ExUnit.Case
  
  setup do
    GenServer.start_link(MockFacts, %{}, name: Facts)
    :ok
  end

  test "Setting the user" do
    assert Elissh.ConnectionRegistry.set_user({"user", "password"}) == :ok
    assert Elissh.ConnectionRegistry.set_user({"user", nil}) == :ok
  end

  test "connecting to single host" do
    Elissh.ConnectionRegistry.set_user({"user", "password"})
    assert Elissh.ConnectionRegistry.connect({:single, {"test", "127.0.0.1"}}) == :ok
  end

  test "connecting to multiple hosts" do
    Elissh.ConnectionRegistry.set_user({"user", "password"})
    assert Elissh.ConnectionRegistry.connect({:multiple, [{"test1", "127.0.0.1"}, {"test2", "127.0.0.2"}]}) == [:ok, :ok]
  end

  test "running on a single host" do
    Elissh.ConnectionRegistry.set_user({"user", "password"})
    Elissh.ConnectionRegistry.connect({:single, {"test", "127.0.1.1"}})
    assert Elissh.ConnectionRegistry.run({:single, {"test", "127.0.1.1"}}, "echo hello") == :ok
  end

  test "running on multiple hosts" do
    Elissh.ConnectionRegistry.set_user({"user", "password"})
    Elissh.ConnectionRegistry.connect({:multiple, [{"test1", "127.0.0.1"}, {"test2", "127.0.0.2"}]})
    assert Elissh.ConnectionRegistry.run({:multiple, [{"test1", "127.0.0.1"}, {"test2", "127.0.0.2"}]}, "echo hello") == :ok
  end
end

defmodule MockFacts do
  def init(any), do: {:ok, any}
  def handle_call(_opts, _from, map), do: {:reply, map, map}
end
