defmodule DefaultConfig do
  defstruct [
    config_file:  "./hosts.yml",
    facts_file:  "./facts.yml",
    all: false,
    password: nil,
    user: System.get_env("USERNAME"),
    interactive: false,
    script: false,
    help: false,
    cmd: ""
  ]
  defimpl Collectable, for: DefaultConfig do
    def into(original) do
      {original, fn
        map, {:cont, {k, v}} -> :maps.put(k, v, map)
        map, :done -> map
        _, :halt -> :ok
      end}
    end
  end
end
