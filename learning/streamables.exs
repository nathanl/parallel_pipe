# Attempt at a lazy enumerable, aka a stream, using a function.
defmodule StreamTest do
  # Every time someone want another value from this stream, we ask the user for input.
  def mindreader do
    # Return a function/2, which already has an Enumerable implementation: when
    # you call Enumerable.reduce(the_function, {cmd, acc}, some_reducer) the impl
    # just calls the_function.({cmd, acc}, some_reducer).
    &(do_mindreading/2)
  end

  defp do_mindreading {:halt, acc}, _fun do
    {:halted, acc}
  end

  defp do_mindreading {:suspend, acc}, fun do
    {:suspended, acc, &(do_mindreading(&1, fun))}
  end

  defp do_mindreading {:cont, acc}, fun do
    case IO.gets "Someone wants us to emit a value. What shall it be? ('quit' to be :done) " do
      "quit\n" -> {:done, acc}
      value -> do_mindreading(fun.(value, acc), fun)
    end
  end
end



defmodule FancyRange do
  # If to is unspecified, it'll emit forever, because (from > to) is always
  # false in Enumerable.reduce().
  defstruct from: 0, to: nil, step: 1
end

defimpl Enumerable, for: FancyRange do
  def reduce(_,    {:halt,    acc}, _fun), do: {:halted, acc}
  def reduce(enum, {:suspend, acc},  fun), do: {:suspended, acc, &(reduce(enum, &1, fun))}
  def reduce(enum, {:cont,    acc}, _fun) when enum.from > enum.to, do: {:done, acc}
  def reduce(enum, {:cont,    acc},  fun), do
    reduce(%{enum | from: enum.from + enum.step}, fun.(enum.from, acc), fun)
  end

  def member?(_,_) do
    {:error, __MODULE__}
  end
  def count(_) do
    {:error, __MODULE__}
  end
end
