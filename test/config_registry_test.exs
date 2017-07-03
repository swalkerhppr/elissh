defmodule Elissh.ConfigRegistryTest do
  use ExUnit.Case
  require Logger

  import YamlElixir.Sigil

  @config ~y"""
  ---
    group1:
      host1: 127.0.0.1
      host2: 127.0.0.2
      host3: 127.0.0.3
      host4: 127.0.0.4
    group2:
      host1: 127.0.1.1
      host2: 127.0.1.2
      host3: 127.0.1.3
    group3:
      host1: 127.0.2.1
      host2: 127.0.2.2
    group5:
      host9: 127.0.3.1
  """

  setup do 
    {:ok, _ } = Elissh.ConfigRegistry.start_link(@config)
    :ok
  end

  test "pulling group config" do
    assert Elissh.ConfigRegistry.get({:spec, "group3"}) == {:multiple, [{"host1", "127.0.2.1"}, {"host2", "127.0.2.2"}]}
    assert Elissh.ConfigRegistry.get({:spec, "group5"}) == {:single, {"host9", "127.0.3.1"}}
    assert Elissh.ConfigRegistry.get({:spec, "group4"}) == :error
  end
  test "pulling host config" do
    assert Elissh.ConfigRegistry.get({:spec, "host4"}) == {:single, {"host4", "127.0.0.4"}}
    assert Elissh.ConfigRegistry.get({:spec, "host1"}) == {:multiple, [{"host1", "127.0.0.1"},{"host1", "127.0.1.1"},{"host1", "127.0.2.1"}]}
    assert Elissh.ConfigRegistry.get({:spec, "host10"}) == :error
  end
end
