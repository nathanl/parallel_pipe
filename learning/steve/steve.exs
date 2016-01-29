# Steve: an enumerable that is a wrapper around some other enumerable running
# in a child process.

defmodule Steve do # "What kind of a wrapping name is 'Steve'?" - FotC
  defstruct enum: nil

  def wrap(enum), do: %Steve{enum: enum}
end

defimpl Enumerable, for: Steve do
  def reduce(steve, {cmd, acc}, callback) do
    parent = self
    child = spawn_link fn -> 
      # TODO: limit to 10 in the send queue
      Enum.each(steve.enum, fn el -> send parent, {self, :have_an_element, el} end)
      send parent, {self, :thats_all}
    end

    recv(child, {cmd, acc}, callback)
  end

  defp recv(child, {:suspend, acc}, callback), do: {:suspended, acc, &(recv(child, &1, callback))}
  defp recv(child, {:halt, acc}, _callback),   do: halt(child, acc)
  defp recv(child, {:cont, acc}, callback)     do
    receive do
      {^child, :have_an_element, el} -> 
        {new_cmd, new_acc} = callback.(el, acc)
        recv(child, {new_cmd, new_acc}, callback)
      {^child, :thats_all} -> 
        {:done, acc}
    end
  end

  defp halt(child, acc) do
    # TODO question: if the parent dies, does the child die?
    # if not, we need to kill the children's children too in this case.
    Process.exit(child, :normal)
    {:halted, acc}
  end

  def count(steve), do: Enumerable.count(steve.enum)
  def member?(steve, value), do: Enumerable.member?(steve.enum, value)
end
