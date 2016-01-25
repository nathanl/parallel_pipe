require Steve

x = 1..10
y = Stream.map(x, &(&1 * 3))
z = Stream.filter(y, &(rem(&1, 2) == 0))
w = Enum.to_list(z)
IO.inspect(w)

x = Steve.wrap(1..10)
y = Steve.wrap(Stream.map(x, &(&1 * 3)))
z = Steve.wrap(Stream.filter(y, &(rem(&1, 2) == 0)))
w = Enum.to_list(z)
IO.inspect(w)
