defmodule Elissh.FactRegistry do
  use GenServer

  @doc "Start fact registry"
  def start_link(init_facts), do: GenServer.start_link(__MODULE__, Map.merge(%{global_facts: %{}}, init_facts), name: Facts)

  @doc "Add a fact associated to a host"
  def put(host, {fact, value}), do: GenServer.call(Facts, {:put, host, fact, value})
  def put(host, map = %{}), do: GenServer.call(Facts, {:put, host, map})

  @doc "Get facts associated with a host"
  def get(host), do: GenServer.call(Facts, {:get, host})

  def replace_facts({host, address}, cmd) do
    host
    |> get
    |> Map.to_list
    |> Enum.concat([{"name", host}, {"address", address}])
    |> Enum.reduce(cmd, &Regex.replace(~r/\#{#{elem(&1, 0)}}/, &2, elem(&1, 1)))
  end

  def extract_facts({host, address}, input, output) do
    case Regex.named_captures(~R/#{>(?<regex>.*)}/, input) do
      %{"regex" => cap_regex} -> put({host, address}, Regex.named_captures(~r/#{cap_regex}/, output))
      _  -> :ok
    end
    output
  end

  def handle_call({:put, {host, _}, fact, value}, _from, map) do
    case map do
      %{^host => host_fact_map} -> 
        {:reply, :ok, %{map | host => Map.merge(host_fact_map, %{fact => value})}}
      _ -> 
        {:reply, :ok, Map.merge(map, %{host => %{fact => value}})}
    end
  end

  def handle_call({:put, {host, _}, fact_map = %{}}, _from, map) do
    case map do
      %{^host => host_fact_map} -> 
        {:reply, :ok, %{map | host => Map.merge(host_fact_map, fact_map)}}
      _ -> 
        {:reply, :ok, Map.merge(map, %{host => fact_map})}
    end
  end

  def handle_call({:get, host}, _from, map = %{global_facts: global_facts}), do: {:reply, Map.merge(global_facts, Map.get(map, host, %{})), map}

  def init(facts), do: {:ok, facts}
end
