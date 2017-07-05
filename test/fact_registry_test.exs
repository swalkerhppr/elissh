defmodule Elissh.FactRegistryTest do
  use ExUnit.Case

  setup do 
    {:ok, _ } = Elissh.FactRegistry.start_link()
    :ok
  end

  test "replacing facts in commands" do
    Elissh.FactRegistry.put({"host", "address"}, {"foo", "hello"})
    Elissh.FactRegistry.put({"host", "address"}, {"bar", "world"})
    assert Elissh.FactRegistry.replace_facts({"host", "address"} , ~S"echo #{foo} #{bar}!") == "echo hello world!"
  end

  test "extracting a simple fact from commands" do
    Elissh.FactRegistry.extract_facts({"host", "address"}, ~S"echo hello #{>(?<var>\w+)}", "hello")
    assert Elissh.FactRegistry.get("host") === %{"var" => "hello"}
  end

  test "extracting a variable from a statement from commands" do
    Elissh.FactRegistry.extract_facts({"host", "address"}, ~S"echo an extracted statement #{>an (?<var>\S+) statement}", "an extracted statement")
    assert Elissh.FactRegistry.get("host") === %{"var" => "extracted"}
  end

  test "extracting a regex variable with regex from commands" do
    Elissh.FactRegistry.extract_facts({"host", "address"}, ~S"echo 1234baddadCool #{>[0-9]+(?<var>[abd]+)}", "1234baddad")
    assert Elissh.FactRegistry.get("host") === %{"var" => "baddad"}
  end

  test "not replacing capture facts in commands" do
    Elissh.FactRegistry.put({"host", "address"}, {"bar", "world"})
    assert Elissh.FactRegistry.replace_facts({"host", "address"} , ~S"echo #{bar}! #{>(?<foo>.*)}") == ~S"echo world! #{>(?<foo>.*)}"
  end

  test "extracting and then using" do
    Elissh.FactRegistry.extract_facts({"host", "address"}, ~S"echo an extracted statement #{>an (?<var>\S+) statement}", "an extracted statement")
    assert Elissh.FactRegistry.replace_facts({"host", "address"}, ~S"echo #{var} is var") == "echo extracted is var"
  end

end
