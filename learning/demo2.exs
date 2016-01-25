#usage: elixir -r bar.exs demo2.exs

require Bar

bar1 = %Bar{lst: [1,  2,  3,  4  ], len: 4}
bar2 = %Bar{lst: ['a','b','c','d'], len: 4}

isnt_2c = fn 
  2, 'c' -> false
  _, _ -> true
end

IO.puts "Demo comparing list comprehensions to doing it manually without syntactic sugar."
IO.puts ""

IO.puts "Running a list comp with 2 generators (1-4 and 'a'-'d') and 1 filter (no '2c')."
IO.puts ""

output = for bar1_el <- bar1, bar2_el <- bar2, isnt_2c.(bar1_el, bar2_el) do
  "#{bar1_el}#{bar2_el}"
end

IO.puts ""
IO.puts "Result:"
IO.inspect output

IO.puts ""
IO.puts ""

IO.puts "Running the same thing, but manually with Enumerable.reduce."
IO.puts ""

initial_acc = []
outer_result = Enumerable.reduce(bar1, {:cont, initial_acc}, fn bar1_el, fn1_acc -> 
  # fn1_acc will initially be [] and will keep getting bigger.  note that we
  # pass fn1_acc into the below inner reduce as its initial accumulator, which will
  # be assigned to fn2_acc each time.  So we're using different variable names,
  # but we're really just building up one long list.
  #
  # Also note that we're building up the list in reverse and then reversing it
  # at the end, because that seems to be the efficient way.  But we could have
  # appended to the accumulator each time to avoid calling :lists.reverse() at
  # the end.
  inner_result = Enumerable.reduce(bar2, {:cont, fn1_acc}, fn bar2_el, fn2_acc ->

    if isnt_2c.(bar1_el, bar2_el) do
      fn2_acc = ["#{bar1_el}#{bar2_el}"|fn2_acc]
    end
    {:cont, fn2_acc}

  end) |> elem(1) 

  {:cont, inner_result}
end) |> elem(1)

output = outer_result |> :lists.reverse()

IO.puts ""
IO.puts "Result:"
output |> IO.inspect
