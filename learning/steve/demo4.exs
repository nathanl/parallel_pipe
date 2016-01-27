# usage: 
#  elixir -r debug_steve.exs demo4.exs
# or
#  elixir -r steve.exs demo4.exs
# to see it without the debugging output.

require Steve

IO.puts "Demo of wrapper that runs pipes eagerly in subprocesses."
IO.puts ""

IO.puts "First: 1..6 | Stream.map(triple) | Stream.filter(evens) | Enum.to_list."

x = 1..6
y = Stream.map(x, &(&1 * 3))
z = Stream.filter(y, &(rem(&1, 2) == 0))
w = Enum.to_list(z)
IO.inspect(w)

IO.puts ""
IO.puts "Now, the same thing but each of the Streams is wrapped to run in"
IO.puts "its own process as fast as possible."
IO.puts ""

# All 3 of the below paragraphs are equivalent, but the last one is the
# prettiest.

# x = Steve.wrap(1..6)
# y = Steve.wrap(Stream.map(x, &(&1 * 3)))
# z = Steve.wrap(Stream.filter(y, &(rem(&1, 2) == 0)))
# w = Enum.to_list(z)
# IO.inspect(w)
# 
# x = 1..6
# x = Steve.wrap(x)
# y = Stream.map(x, &(&1 * 3))
# y = Steve.wrap(y)
# z = Stream.filter(y, &(rem(&1, 2) == 0))
# z = Steve.wrap(z)
# w = Enum.to_list(z)
# IO.inspect(w)

1..6
|> Steve.wrap
|> Stream.map(&(&1 * 3)) 
|> Steve.wrap
|> Stream.filter(&(rem(&1, 2) == 0))
|> Steve.wrap
|> Enum.to_list 
|> IO.inspect
