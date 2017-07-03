use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :elissh, :sshmodule, AllOKMock


defmodule AllOKMock do
  def connect(_,_,_,_), do: {:ok, :mocked}
  def session_channel(_,_), do: {:ok, :mocked}
  def exec(_,_,_,_), do: :success
  def adjust_window(_,_,_), do: :ok
  def close(_, _), do: :ok
end
