# NOTE:
# This is steve.exs with a bunch of ugly debugging printouts thrown in that
# make it much harder to read the code.

defmodule Debug do
  # Ignore this messy function.  It just prints some nice debug output.
  def print dir, from, to, value, pad \\ 0 do
    to_s = fn p -> p |> :erlang.pid_to_list |> Kernel.to_string |> String.slice(3..4) end
    purty = fn pid_string -> max 0, String.to_integer(to_s.(pid_string)) - 63 end
    IO.puts "#{String.rjust dir, pad}: #{purty.(from)} -> #{purty.(to)} : #{value}"
  end
end

defmodule Steve do # "What kind of a wrapping name is 'Steve'?" - FotC
  defstruct enum: nil, max_buffer: -1

  def wrap(enum),             do: %Steve{enum: enum}
  def wrap(enum, max_buffer), do: %Steve{enum: enum, max_buffer: max_buffer}
end

defimpl Enumerable, for: Steve do
  def reduce(steve, {cmd, acc}, fun) do
    parent = self
    child = spawn_link fn -> 
      Enum.reduce(steve.enum, steve.max_buffer, fn el, buffer_left ->
        if buffer_left == 0 do
          IO.puts "Child: Buffer is full.  Waiting for an ack from my parent."
          receive do: (:ack -> nil)
          IO.puts "Child: I got the ack."
          buffer_left = 1
        end
        Debug.print "SENT", self, parent, el
        send parent, {self, :have_an_element, el}
        buffer_left - 1
      end)
      Debug.print "SENT", self, parent, ":thats_all"
      send parent, {self, :thats_all}
    end

    recv(child, {cmd, acc}, fun)
  end

  defp recv(child, {:suspend, acc}, fun), do: {:suspended, acc, &(recv(child, &1, fun))}
  defp recv(child, {:halt, acc}, _fun),   do: halt(child, acc)
  defp recv(child, {:cont, acc}, fun)     do
    receive do
      {^child, :have_an_element, el} ->
        Debug.print "RCVD", child, self, el, 30
        send child, :ack
        recv(child, fun.(el, acc), fun)
      {^child, :thats_all} ->
        Debug.print "RCVD", child, self, ":thats_all", 30
        {:done, acc}
    end
  end

  defp halt(child, acc) do
    Process.exit(child, :normal)
    {:halted, acc}
  end

  def count(steve), do: Enumerable.count(steve.enum)
  def member?(steve, value), do: Enumerable.member?(steve.enum, value)
end
