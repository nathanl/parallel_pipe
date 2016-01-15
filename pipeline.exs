# Get a list of functions
# Start one child process per function
# Make list/tuple of statuses, one per child process, like :idle or :busy
# Make an outbox queue for each child process
# forever:
# for each outbox:
#   if outbox is not empty, and
#      recipient is idle, and
#      recipient's outbox is not jammed full:
#     send item from outbox to recipient
#     mark recipient as :busy
# receive nonblocking {:more, [stuff]} from any sender
#   -> put stuff in his outbox,
#   -> mark sender as :idle
# receive nonblocking {:done, [stuff]} from any sender
#   -> put stuff in his outbox,
#   -> terminate all guys before and including sender
# if there are no more dudes left alive,
# return! profit! PS: there is no return in Elixir :(

# Things we need to know how to do:
# 1. create a child process
# 2. send a message to a child and get a message back.
# 3. put a message in a queue.
# 4. mark them as :idle or :busy which, since we can't have state,
#     really means accumulating this data.
# 5. instead of a forloop, do some horrible reduce or something.
# 6. instead of 'loop forever', call ourselves tail-recursively.

defmodule Pipeline do

  def start(functions) when is_list(functions) do
    Enum.each(functions, fn (function) -> function.() end)
  end

end

Pipeline.start([(fn -> IO.puts "cake" end), (fn -> IO.puts "pie" end)])
