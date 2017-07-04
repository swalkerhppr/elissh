defmodule Elissh.ConfigRegistry do
  use GenServer, YamlElixir

  @doc """
    Start the config Registry
  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: Config) 
  end

  @doc """
    Get a record in the config registry
  """
  def get({:spec, name }) do
    GenServer.call(Config, {:spec, name})
  end

  def init(:ok, config) do
    {:ok, config}
  end

  def handle_call({:spec, name}, _from, map ) do
    result = (Enum.map(map, fn {_, vals} -> {name, vals[name]} end) |> Enum.filter(fn {_, ip} -> ip != nil end)) ++ (Map.get(map, name, %{}) |> Map.to_list)
    case length(result) do
      0 -> {:reply, :error, map}
      1 -> {:reply, {:single, hd(result)}, map}
      _ -> {:reply, {:multiple, result}, map}
    end
  end

end
