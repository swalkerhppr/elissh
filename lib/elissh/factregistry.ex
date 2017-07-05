defmodule Elissh.FactRegistry do
  use GenServer

  def start_link(init_facts) do
    GenServer.start_link(__MODULE__, Map.merge(%{global_facts: %{}}, init_facts), name: Facts)
  end

  def put(host, {fact, value}) do
    GenServer.call(Facts, {:put, host, fact, value})
  end

  def get(host) do
    GenServer.call(Facts, {:get, host})
  end

  def replace_facts({host, address}, cmd) do
    case Map.to_list(get(host)) do
      facts ->
        Enum.reduce([cmd | facts] ++ [{"name", host},{"address", address}], fn({fact, value}, acc) -> Regex.replace(~r/\#{#{fact}}/, acc, value) end)
      [] -> cmd
    end
  end

  def extract_facts({host, address}, input, output) do
    named = Regex.named_captures(~R/#{>(?<regex>.*)}/, input) 
    case named do
      %{"regex" => cap_regex} -> 
        put({host, address}, List.first(Map.to_list(Regex.named_captures(~r/#{cap_regex}/, output))))
      _  -> :ok
    end
    output
  end

  def handle_call({:put, {host, address}, fact, value}, _from, map) do
    case map do
      %{^host => host_fact_map} -> 
        {:reply, :ok, %{map | host => Map.merge(host_fact_map, %{fact => value})}}
      _ -> 
        {:reply, :ok, Map.merge(map, %{host => %{fact => value}})}
    end
  end

  def handle_call({:get, host}, _from, map) do
    {:reply, Map.merge(map[:global_facts], Map.get(map, host, %{})), map}
  end

  def init(facts) do
    {:ok, facts}
  end
end
