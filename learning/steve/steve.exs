# Steve: an enumerable that is a wrapper around some other enumerable running
# in a child process.

defmodule Steve do # "What kind of a wrapping name is 'Steve'?" - FotC
  defstruct enum: nil, max_buffer: -1

  def wrap(enum),             do: %Steve{enum: enum}
  def wrap(enum, max_buffer), do: %Steve{enum: enum, max_buffer: max_buffer}
end

defimpl Enumerable, for: Steve do
  def reduce(steve, {cmd, acc}, callback) do
    parent = self

    send_to_parent_with_buffering = fn el, buffer_remaining ->
      if buffer_remaining == 0 do
        receive do: (:ack -> nil)
        buffer_remaining = 1
      end
      send parent, {self, :have_an_element, el}
      buffer_remaining - 1
    end

    child = spawn_link fn -> 
      Enum.reduce(steve.enum, steve.max_buffer, send_to_parent_with_buffering)
      send parent, {self, :thats_all}
    end

    recv(child, {cmd, acc}, callback)
  end

  defp recv(child, {:suspend, acc}, callback), do: {:suspended, acc, &(recv(child, &1, callback))}
  defp recv(child, {:halt, acc}, _callback),   do: halt(child, acc)
  defp recv(child, {:cont, acc}, callback)     do
    receive do
      {^child, :have_an_element, el} -> 
        send child, :ack
        result = {new_cmd, new_acc} = callback.(el, acc)
        recv(child, result, callback)
      {^child, :thats_all} -> 
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
