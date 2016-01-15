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
      :now -> send parentpid, {self, fun.()}
    end
    foo(parentpid, fun)
  end

  def go(pids, state) do
    # stuff and then
    receive do
      {childpid, message} ->
        # IO.puts "At start, here are the state:"
        # IO.inspect(state)
        case message do
          "cake" -> IO.inspect ["Message from", childpid, message]
          "pie" -> :do_nothing
        end

        send childpid, :now

        pos = state[childpid].pos
        newqueue = [message | state[childpid].queue]
        newstate = put_in(state, [childpid, :queue], newqueue)

        next_proc_info =
          Enum.find(state, fn {_, %{:pos => p}} -> p == pos + 1 end)

        IO.inspect ["next proc info is", next_proc_info]

        case next_proc_info do
          nil -> IO.puts "nobody is after that guy!"
          {next_func_pid, _} -> send next_func_pid, :now
        end
    end

    go(pids, newstate)
  end

  def start(functions) when is_list(functions) do
    parentpid = self
    child_pids = Enum.map(functions, fn (function) -> 
      spawn_link(fn ->
        foo(parentpid, function)
      end)
    end)

    send hd(child_pids), :now

    go(child_pids, 
       child_pids 
       |> Enum.with_index
       |> Enum.map(fn {pid, i} -> {pid, %{pos: i, queue: [], status: :busy}} end) 
       |> Enum.into(%{})
    )
  end

end

Pipeline.start([fn -> "cake" end, fn -> "pie" end])
