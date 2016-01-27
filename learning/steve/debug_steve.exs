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
  defstruct enum: nil

  def wrap(enum), do: %Steve{enum: enum}
end

defimpl Enumerable, for: Steve do
  def reduce(steve, {cmd, acc}, fun) do
    parent = self
    child = spawn_link fn -> 
      Enum.each(steve.enum, fn el -> 
        Debug.print "SENT", self, parent, el
        send parent, {self, :have_an_element, el} 
      end)
      Debug.print "SENT", self, parent, ":done"
      send parent, {self, :done}
    end

    recv(child, {cmd, acc}, fun)
  end

  defp recv(child, {:suspend, acc}, fun), do: {:suspended, acc, &(recv(child, &1, fun))}
  defp recv(child, {:halt, acc}, _fun),   do: halt(child, acc)
  defp recv(child, {:cont, acc}, fun)     do
    receive do
      {^child, :have_an_element, el} ->
        Debug.print "RCVD", child, self, el, 30
        recv(child, fun.(el, acc), fun)
      {^child, :done} ->
        Debug.print "RCVD", child, self, ":done", 30
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
