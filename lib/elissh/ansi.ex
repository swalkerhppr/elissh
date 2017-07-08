defmodule Elissh.ANSI do

  def start do
    pid = spawn(&handle_msgs/0)
    Process.register(pid, Interpreter)
    {:ok, pid}
  end

  def handle_msgs(input \\ "", reply_to \\ self()) do
    receive do
      {port, {:data, d}} ->
        case d do
         << 13 >> -> 
            send reply_to, {:reply, input}
            Port.close(port)
          << b >> when b in 32..127 ->
            IO.write(<< b >>)
            handle_msgs(input <> d, reply_to)
        end
      {:gets, caller} ->
        handle_msgs(input, caller)
      _ ->
        IO.write("STOP!")
    end
  end

  def gets(prompt) do
    IO.write(prompt)
    wait_for_input()
  end

  defp wait_for_input() do
    {:ok, pid} = start()
    Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof]) |> Port.connect(pid)
    send Interpreter, {:gets, self()}
    receive do
      {:reply, d} -> d 
    end
  end

end
