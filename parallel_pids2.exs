defmodule Mappy do
  def stream(coll, ident, func) do
    IO.puts "stream #{ident} got a collection"
    :timer.sleep(1_000)
    Stream.map(coll, fn (num) ->
      :timer.sleep(500)
      IO.puts "stream #{ident} got item #{num}"
      func.(num)
    end)
  end

  def sync(coll, ident, func) do
    IO.puts "sync   #{ident}  got a collection"
    :timer.sleep(1_000)
    Enum.map(coll, fn (num) ->
      :timer.sleep(500)
      IO.puts "sync   #{ident} got item #{num}"
      func.(num)
    end)
  end
end

1..3
|> Mappy.stream(:one, &(&1))
|> Mappy.stream(:two, &(&1))
|> Mappy.sync(:one, &(&1))
|> IO.inspect

# This is not good enough because only one item is traveling down the conveyor belt at a time. I went to hear a chorus of "starting work" from all machines as they each get a new item simultaneously.

# Stream.resource or transform
# webfaction - michael/elixir/stream.ex
