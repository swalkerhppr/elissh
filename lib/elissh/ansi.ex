defmodule Elissh.ANSI do


  def gets(prompt) do
    IO.write(prompt)
    wait_for_input()
  end

  defp handle_msgs(input \\ "", cursor \\ 0, reply_to \\ nil) do
    receive do
      {port, {:data, chardata}} -> 
        case handle_key(chardata, cursor, input,  port, reply_to) do
          {inp, cur, reply} -> handle_msgs(inp, cur, reply)
          :stop -> {:EXIT, self(), :normal}
        end
      {:gets, caller} -> handle_msgs(input, cursor, caller)
    end
  end

  defp wait_for_input() do
    pid = Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof]) |> start_receiver()
    send pid, {:gets, self()}
    receive do
      {:reply, d} -> d 
    end
  end

  defp start_receiver(port) do
    Port.connect(port, pid = spawn(&handle_msgs/0))
    pid
  end

  @fw "\e[C"
  @bk "\e[D"
  @tab "\t"
  @ret "\r"
  @del "\d"

  defp handle_key(@fw, cursor, input, _, reply_to) do
    IO.write(@fw)
    {input, cursor+1, reply_to}
  end
  defp handle_key(@bk, cursor, input, _, reply_to) do
    case cursor do
      0 -> 
        {input, cursor, reply_to}
      _ ->
        IO.write(@bk)
        {input, cursor-1, reply_to}
    end
  end
  defp handle_key(@tab, cursor, input, _, reply_to) do
    {input, cursor, reply_to}
  end
  defp handle_key(@ret, _, input, port, reply_to) do
    IO.write("\n")
    send reply_to, {:reply, input}
    Port.close(port)
    :stop
  end
  defp handle_key(@del, cursor, input, _, reply_to) do
    {pre, post} = cut(input, cursor)
    IO.write(@bk <> " " <> @bk)
    {pre <> post , cursor-1, reply_to}
  end
  defp handle_key(<< b >>, cursor, input,  _, reply_to) when b in 32..126 do
    {pre, post} = cut(input, cursor)
    IO.write(<< b >> <> post <> String.duplicate(@bk, String.length(post)))
    {pre <> << b >> <> post, cursor+1, reply_to}
  end

  defp cut(input, cursor), do: {String.slice(input, 0..cursor-1), String.slice(input, cursor..-1)}

end
