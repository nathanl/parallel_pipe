defmodule Mappy do
  def m(coll, :stream) do
    IO.puts "stream got a collection"
    :timer.sleep(1_000)
    Stream.map(coll, fn (num) ->
      IO.puts "stream got item #{num}"
      num
    end)
  end

  def m(coll, :sync) do
    IO.puts "sync   got a collection"
    :timer.sleep(1_000)
    Enum.map(coll, fn (num) ->
      IO.puts "sync   got item #{num}"
      num
    end)
  end
end

1..3 
|> Mappy.m(:stream)
|> Mappy.m(:stream)
|> Mappy.m(:sync)
|> IO.inspect
