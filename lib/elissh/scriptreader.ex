defmodule Elissh.ScriptReader do
  use GenServer

  def start_link(script) do
    file_contents = File.read!(script)
    GenServer.start_link(__MODULE__, String.split(file_contents, "\n"), name: Reader)
  end

  def next() do
    GenServer.call(Reader, :next)
  end

  def init(file_info) do
    {:ok, file_info}
  end

  def handle_call(:next, _from, contents) do
    try do
      {:reply, hd(contents), tl(contents)}
    rescue
      ArgumentError -> {:reply, "!exit", contents}
    end
  end
end
