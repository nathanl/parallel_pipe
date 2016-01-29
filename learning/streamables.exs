# Mixin for Enumerable implementations that does most of the work.
#
# Usage:
# defimpl Enumerable, for: SomeModule do
#   use Enumerable.Mixin
#   def empty?(enum), do: #true if enum is empty
#   def pop(enum), do: {first_item, enum_without_first_item}
# end
defmodule Enumerable.Mixin do
  defmacro __using__(_) do
      quote do
      def reduce(enum, {cmd, acc}, fun), do: r(enum, {cmd, acc}, fun)

      defp r(_,    {:halt,    acc}, _fun), do: {:halted, acc}
      defp r(enum, {:suspend, acc},  fun), do: {:suspended, acc, &(r(enum, &1, fun))}
      defp r(enum, {:cont,    acc},  fun) do
        case empty?(enum) do
          true  -> {:done, acc}
          false ->
            {el, smaller_enum} = pop(enum)
            {new_cmd, new_acc} = fun.(el, acc)
            r(smaller_enum, {new_cmd, new_acc}, fun)
        end
      end

      def member?(_,_), do: {:error, __MODULE__}
      def count(_),     do: {:error, __MODULE__}
      end
    end
end

# Attempt at a lazy enumerable, aka a stream, using a function.
defmodule StreamTest do
  # Every time someone want another value from this stream, we ask the user for input.
  def mindreader do
    # Return a function/2, which already has an Enumerable implementation: when
    # you call Enumerable.reduce(the_function, {cmd, acc}, some_reducer) the impl
    # just calls the_function.({cmd, acc}, some_reducer).
    &(do_mindreading/2)
  end

  # Does the same thing as mindreader() but we return a StreamTest (and defimpl
  # Enumerable for it below) instead of returning a function/2 (which has a built-in
  # Enumerable implementation).
  defstruct input: nil
  def mindreader2, do: %StreamTest{input: IO.gets "Mindreader2: Type a value or 'quit': "}

  defp do_mindreading {:halt, acc}, _fun do
    {:halted, acc}
  end

  defp do_mindreading {:suspend, acc}, fun do
    {:suspended, acc, &(do_mindreading(&1, fun))}
  end

  defp do_mindreading {:cont, acc}, fun do
    case IO.gets "Mindreader: Type a value or 'quit': " do
      "quit\n" -> {:done, acc}
      value -> do_mindreading(fun.(value, acc), fun)
    end
  end
end

defimpl Enumerable, for: StreamTest do
  use Enumerable.Mixin

  defp empty?(enum), do: enum.input == "quit\n"
  defp pop(enum) do
    query = "Mindreader2: Now another, or 'quit': "
    {enum.input, %StreamTest{input: IO.gets(query)}}
  end
end

defmodule FancyRange do
  defstruct from: 0, to: nil, step: 1
end

defimpl Enumerable, for: FancyRange do
  use Enumerable.Mixin

  defp empty?(enum), do: enum.from > enum.to # NB: number > nil is always false
  defp pop(enum = %{from: from, step: step}), do: {enum.from, %{enum | from: from + step}}
end
