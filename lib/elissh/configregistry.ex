defmodule Elissh.ConfigRegistry do
  use GenServer, YamlElixir

  @doc "Start the config Registry"
  def start_link(config), do: GenServer.start_link(__MODULE__, config, name: Config) 

  @doc "Get a record in the config registry"
  def get({:spec, name }), do: GenServer.call(Config, {:spec, name})

  def init(:ok, config), do: {:ok, config}

  def handle_call({:spec, name}, _from, {:ok, map}) do
    (
      map 
      |> Enum.map(fn {_, vals} -> {name, vals[name]} end)
      |> Enum.filter(fn {_, ip} -> ip != nil end)
    ) ++ (
      map
      |> Map.get(name, %{}) 
      |> Map.to_list
    ) 
    |> case do
      [] -> {:reply, :error, map}
      [result] -> {:reply, {:single, result}, map}
      result -> {:reply, {:multiple, result}, map}
    end
  end

end
