# attempt at a lazy enumerable, aka a stream.
defmodule StreamTest do
  # Every time someone want another value from this stream, we ask the user for input.
  def mindreader do
    &(do_mindreading(&1, &2))
  end

  defp do_mindreading {:halt, acc}, _fun do
    {:halted, acc}
  end

  defp do_mindreading {:cont, acc}, fun do
    value = IO.gets "Now what? "
    do_mindreading(fun.(value, acc), fun)
  end
end

StreamTest.mindreader |> Enum.take(3)
|> IO.inspect

simplest_one_item_lazy_enumerable = fn {:cont, acc}, reducer -> 
  now = :calendar.local_time() # not calculated until we are enumerated
  {_now_what, new_acc} = reducer.(now, acc)
  {:done, new_acc}
end

#simplest_one_item_lazy_enumerable |> Stream.take(3) |> Enum.to_list |> IO.inspect
