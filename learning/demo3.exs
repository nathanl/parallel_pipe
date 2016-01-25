require StreamTest
require FancyRange

# usage: elixir -r streamables.exs demo3.exs

IO.puts "Demonstration of defimpl Enumerable, for: function"
IO.puts "being used to lazily generate values when they are requested."
IO.puts "Calling StreamTest.mindreader | Enum.take(3)."
IO.puts ""

StreamTest.mindreader |> Enum.take(3) |> IO.inspect

IO.puts ""
IO.puts "--------------------------"
IO.puts ""

simplest_one_item_lazy_enumerable = fn {:cont, acc}, reducer -> 
  # not calculated until we are enumerated
  {_now_what, new_acc} = reducer.(:calendar.local_time(), acc)
  {:done, new_acc}
end

IO.puts "Demonstration of the simplest one-item lazy enumerable."
simplest_one_item_lazy_enumerable |> Enum.take(3) |> IO.inspect

IO.puts ""
IO.puts "--------------------------"
IO.puts ""


IO.puts "Demonstration of an object that implements Enumerable and generates items"
IO.puts "lazily.  Also it implements :suspend, so zip() works!"
Stream.zip(%FancyRange{from: 2, step: 0.25}, %FancyRange{to: 4}) |> Enum.take(5) |> IO.inspect
