require Steve

x = [1,2,3]
y = Stream.map(x, &(&1 + 2))
z = Enum.to_list(y)
IO.inspect(z)

x = Steve.wrap([1,2,3])
y = Steve.wrap(Stream.map(x, &(&1 + 2)))
z = Enum.to_list(y)
IO.inspect(z)
