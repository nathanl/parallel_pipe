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

  def await_requests(parentpid, fun) do
    receive do
      :emit_a_value -> send parentpid, {self, fun.()}
      {:emit_a_value_and_use_this, x} -> send parentpid, {self, fun.(x)}
    end
    await_requests(parentpid, fun)
  end

  def go(acc) do
    # stuff and then
    receive do
      {child_pid, message} ->
        # Store whatever the child return in its outbox
        state = acc[child_pid]
        state = %{state | outbox: state.outbox ++ [message]}
        acc = Map.put(acc, child_pid, state)

        # Where in the list of functions is the child?
        pos = state.pos

        # Find the sibling so we can hand it a message
        consumer_state =
          Enum.find(acc, fn {_, %{:pos => p}} -> p == pos + 1 end)

        # First one takes no params, just gimme another value
        if pos == 0 do
          send child_pid, :emit_a_value
        end

        # Pop an item from the child's outbox.
        popped_item_from_queue = hd(state.outbox)
        state = %{state | outbox: tl(state.outbox)}
        acc = Map.put(acc, child_pid, state)

        case consumer_state do
          nil -> 
            # Noone is there to receive the item.  Print it.
            IO.puts(popped_item_from_queue)
          {sibling_pid, _} -> 
            # Send the item to the child's sibling.
            send sibling_pid, {:emit_a_value_and_use_this, popped_item_from_queue}
        end
    end

    go(acc)
  end

  def start(functions) when is_list(functions) do
    parentpid = self
    child_pids = Enum.map(functions, fn (function) -> 
      spawn_link(fn ->
        await_requests(parentpid, function)
      end)
    end)

    # tell first one to start
    send hd(child_pids), :emit_a_value

    go(child_pids 
       |> Enum.with_index
       |> Enum.map(fn 
        {pid, 0} -> {pid, %{pos: 0, outbox: [], status: :busy}}
        {pid, i} -> {pid, %{pos: i, outbox: [], status: :idle}}
       end) 
       |> Enum.into(%{})
    )
  end

end

Pipeline.start([
   fn -> :random.uniform end, 
   fn el -> "cake #{el}" end, 
   fn el -> "pie #{el}" end
 ])
