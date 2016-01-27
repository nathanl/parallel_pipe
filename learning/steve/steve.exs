# Steve: an enumerable that is a wrapper around some other enumerable running
# in a child process.

defmodule Steve do # "What kind of a wrapping name is 'Steve'?" - FotC
  defstruct enum: nil

  def wrap(enum), do: %Steve{enum: enum}
end

defimpl Enumerable, for: Steve do
  def reduce(steve, {cmd, acc}, fun) do
    parent = self
    child = spawn_link fn -> 
      Enum.each(steve.enum, fn el -> send parent, {self, :have_an_element, el} end)
      send parent, {self, :done}
    end

    recv(child, {cmd, acc}, fun)
  end

  defp recv(child, {:suspend, acc}, fun), do: {:suspended, acc, &(recv(child, &1, fun))}
  defp recv(child, {:halt, acc}, _fun),   do: halt(child, acc)
  defp recv(child, {:cont, acc}, fun)     do
    receive do
      {^child, :have_an_element, el} -> recv(child, fun.(el, acc), fun)
      {^child, :done} -> {:done, acc}
    end
  end

  defp halt(child, acc) do
    Process.exit(child, :normal)
    {:halted, acc}
  end

  def count(steve), do: Enumerable.count(steve.enum)
  def member?(steve, value), do: Enumerable.member?(steve.enum, value)
end
