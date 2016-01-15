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

  def foo(parentpid, fun) do
    receive do
      :now -> send parentpid, fun.()
    end
    foo(parentpid, fun)
  end

  def go(pids, queues) do
    # stuff and then
    Enum.each(pids, fn pid ->
      send pid, :now
      send pid, :now
      send pid, :now
      send pid, :now
    end)
    1..4 |> Enum.each(fn _ ->
      Enum.each(pids, fn _ ->
        receive do
          message -> IO.puts message
        end
      end)
    end)
    go(pids, queues)
  end

  def start(functions) when is_list(functions) do
    parentpid = self
    child_pids = Enum.map(functions, fn (function) -> 
      spawn_link(fn ->
        foo(parentpid, function)
      end)
    end)

    go(child_pids, child_pids |> Enum.map(fn _ -> [] end))
  end

end

Pipeline.start([fn -> "cake" end, fn -> "pie" end])
