#usage: elixir -r bar.exs exercise.exs

require Bar

IO.puts "Demo that Bar is Enumerable and that my homegrown map/take/reduce work"

%Bar{lst: 1..10 |> Enum.to_list, len: 10}
|> Bar.map(&(&1 + 2))
|> Bar.take(3)
|> Bar.reduce(0, fn el, acc -> el + acc end)
|> IO.inspect

