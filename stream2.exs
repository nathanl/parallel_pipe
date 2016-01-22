#usage: elixir -r stream.exs stream2.exs

require Bar

%Bar{lst: 1..10 |> Enum.to_list, len: 10}
|> Bar.map(&(&1 + 2))
|> Bar.take(3)
|> IO.inspect
