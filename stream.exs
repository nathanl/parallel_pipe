# enum |> Bar.map(&(&1 + 2)) |> in_a_process(uniq) |> Enum.to_list
# 
# aka
# 
# x = foo(enum) # returns an Enumerable, namely a Stream
# y = bar(x) # Same
# z = Enum.to_list(y)
# 
# So foo takes in an Enumerable and:
#   - slurps one item at a time from it
#   - does something with that item
#   - emits one item at a time until it's done - maybe not as many items
#     as it slurped (by yielding [] or [a,b] sometimes0
# 
# e.g. foo should add 2 to each item.
#
#

#def uniq enum do
  # somehow create a list that has the dupes removed
  # storing state in here somehow
  # return that list
#end

defmodule Bar do
  defstruct lst: [], len: 0

  def map(somebar, func) do
    reducer = fn x, acc -> {:cont, %{acc | lst: acc.lst ++ [func.(x)], len: acc.len+1}} end
    {:done, thing} = Enumerable.reduce(somebar, {:cont, %Bar{}}, reducer) 
    thing
   # |> elem(1) |> :lists.reverse()
   # I'm supposed to return anything, as long as it implements the Enumerable protocol.
   # aka I separately define Enumerable.reduce() for it.
   # Enumerable.reduce(me, acc, f)
   # will in turn call func() on each value in enum.
  end

  def take(somebar, n) do
    f = fn 
      _, {acc, 0} -> {:halt, acc}
      x, {acc, i} -> {:cont, {%{acc | lst: acc.lst ++ [x], len: acc.len+1}, i-1}}
    end
    Enumerable.reduce(somebar, {:cont, {%Bar{}, n}}, f)
  end
end

defimpl Enumerable, for: Bar do
  def reduce(somebar=%Bar{lst: [h|t]}, {:cont, acc}, fun) do
    Enumerable.reduce(%{somebar | lst: t, len: somebar.len - 1}, fun.(h, acc), fun)
  end
  def reduce(%Bar{lst: []}, {:cont, acc}, _fun) do
    {:done, acc}
  end
  def reduce(_somebar, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def count(_) do
    {:error, __MODULE__}
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end
end


#     Stream.transform(
#       enum, # enumerable
#       %{},   # accumulator initially
#       fn item, acc_map -> # each item from the enumerable, and your accumulator
#          child.send(item)
#          child.receive(response, |some_stuff| {
#          
#           {some_stuff, acc_map.put(new,data)} # { things to emit, a new accumulator }
# 
#          })
#       end
#     )
# 
#  end
#end

