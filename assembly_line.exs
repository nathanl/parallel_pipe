# Get a list of functions
# Start one worker process per function
# Make list/tuple of statuses, one per worker process, like :idle or :busy
# Make an outbox queue for each worker process
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
# 1. create a worker process
# 2. send a message to a worker and get a message back.
# 3. put a message in a queue.
# 4. mark them as :idle or :busy which, since we can't have state,
#     really means accumulating this data.
# 5. instead of a forloop, do some horrible reduce or something.
# 6. instead of 'loop forever', call ourselves tail-recursively.

# TODO
# - Define a max size for outbox
# - Mark first worker idle if outbox is full
# - After processing an incoming message, start looking through worker's states and outboxes and assigning states and work accordingly.
#
# Run with `elixir assembly_line.exs | head -30`

defmodule AssemblyLine do

  defmodule Worker do
    def await_requests(parentpid, fun) do
      receive do
        :emit_a_value -> send parentpid, {self, fun.()}
        {:process_this, x} -> send parentpid, {self, fun.(x)}
      end
      await_requests(parentpid, fun)
    end
  end

  defmodule Foreman do
    def manage(assembly_line) do
      receive do
        {worker_pid, outputs} ->
          # Store the worker's outputs in its outbox
          state = assembly_line[worker_pid]
          state = %{state | outbox: state.outbox ++ outputs}
          assembly_line = Map.put(assembly_line, worker_pid, state)

          # Where in the list of functions is the worker?
          pos = state.pos

          # Find the next worker so we can hand it a single output
          next_worker_state =
          Enum.find(assembly_line, fn {_, %{:pos => p}} -> p == pos + 1 end)

          # First one takes no params, just gimme another value
          if pos == 0 do
            send worker_pid, :emit_a_value
          end

          assembly_line = case next_worker_state do
            nil -> 
            # End of the line, so print everything it produced
            state.outbox |> Enum.each(fn el -> IO.puts(el) end)
            state = %{state | outbox: []}
            Map.put(assembly_line, worker_pid, state)
            {next_worker_pid, _} -> 
            # Send the item to the next worker
            # TODO - handle case where outbox is empty - hd() will error
            one_item = hd(state.outbox)
            send next_worker_pid, {:process_this, one_item}
            state = %{state | outbox: tl(state.outbox)}
            Map.put(assembly_line, worker_pid, state)
          end
      end

      manage(assembly_line)
    end
  end

  def start(functions) when is_list(functions) do
    manager_pid = self
    worker_pids = Enum.map(functions, fn (function) -> 
      spawn_link(fn ->
        Worker.await_requests(manager_pid, function)
      end)
    end)

    # tell first one to start
    send hd(worker_pids), :emit_a_value

    assembly_line = worker_pids 
       |> Enum.with_index
       |> Enum.map(fn 
        {pid, 0} -> {pid, %{pos: 0, outbox: [], status: :busy}}
        {pid, i} -> {pid, %{pos: i, outbox: [], status: :idle}}
       end) 
       |> Enum.into(%{})

    Foreman.manage(assembly_line)
  end

end

AssemblyLine.start([
   fn -> [:random.uniform] end,
   fn number -> ["cake #{number}"] end,
   fn cake -> ["eat  #{cake}", "poop #{cake}"] end
 ])
