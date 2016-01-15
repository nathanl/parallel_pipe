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

def uniq enum do
  # somehow create a list that has the dupes removed
  # storing state in here somehow
  # return that list
end

defmodule Bar do
  def map(enum, func) do

    Stream.transform(
      enum, # enumerable
      %{},   # accumulator initially
      fn item, acc_map -> # each item from the enumerable, and your accumulator
         child.send(item)
         child.receive(response, |some_stuff| {
         
          {some_stuff, acc_map.put(new,data)} # { things to emit, a new accumulator }

         })
      end
    )

  end
end

1..10
|> Bar.map(&(&1 + 2))
|> Enum.to_list
|> IO.inspect
