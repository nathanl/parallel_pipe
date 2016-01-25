# A lazy enumerable that is a wrapper around some other enumerable running in a
# child process.

defmodule Steve do # "What kind of a wrapping name is 'Steve'?" - FotC
  defstruct child: nil, value: nil

  defmodule Child do
    def await_requests_about song do
      {:suspended, _, continuation} = Enumerable.reduce(song, {:suspend, nil}, fn el, _ ->
        IO.inspect ["DEBUG", self, "emitting", el]
        {:suspend, el}
      end)

      loop continuation
    end

    defp loop continuation do
      receive do
        {parent, :sing_more} ->
          result = continuation.({:cont, nil})
          case result |> elem(0) do
            :suspended ->
              value = result |> elem(1)
              continuation = result |> elem(2)
              send parent, {:ok, value}
              loop continuation
            :done ->
              send parent, :song_is_done
          end
      end
    end
  end

  def wrap song do
    %Steve{child: spawn_link fn -> Child.await_requests_about song end}
  end
end

defimpl Enumerable, for: Steve do
  def reduce(_steve, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(steve, {:suspend, acc}, fun) do
    {:suspended, acc, &(reduce(steve, &1, fun))}
  end

  def reduce(steve, {:cont, acc}, fun) do
    send steve.child, {self, :sing_more}
    receive do
      :song_is_done -> 
        # TODO: kill child (harsh, but fair)
        {:done, acc}
      {:ok, value} -> 
        reduce(steve, fun.(value, acc), fun)
    end
  end

  def count _ do
    {:error, __MODULE__}
  end

  def member? _, _ do
    {:error, __MODULE__}
  end
end
