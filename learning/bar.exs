defmodule Bar do
  defstruct lst: [], len: 0

  def append(somebar = %Bar{lst: lst, len: len}, el) do
    %{somebar | lst: lst ++ [el], len: len+1}
  end

  def pop(somebar = %Bar{lst: [h|t], len: len}) do
    {h, %{somebar | lst: t, len: len-1}}
  end

  def map(somebar, func) do
    reducer = fn x, bar_acc -> {:cont, Bar.append(bar_acc, func.(x))} end
    {:done, thing} = Enumerable.reduce(somebar, {:cont, %Bar{}}, reducer) 
    thing
  end

  def take(somebar, n) do
    f = fn 
      _, {bar_acc, i} when i <= 0 -> {:halt, bar_acc} 
      el, {bar_acc, i} -> {:cont, {Bar.append(bar_acc, el), i-1}}

    end
    Enumerable.reduce(somebar, {:cont, {%Bar{}, n}}, f) |> elem(1)
  end

  # This function implementation really highlights that Enumerable.reduce() is
  # mostly a regular reduce with an annoying {:cont} that you have to pass
  # around along with the accumulator.  But of course, Enumerable.reduce() can
  # also be halted early or suspended, which Bar.reduce() can't.
  #
  # Also worth mentioning that this is a useless function, because it doesn't
  # do anything Bar-specific.  Enum.reduce() is basically identical.
  def reduce(somebar, acc, fun) do
    {:done, result} = Enumerable.reduce(somebar, {:cont, acc}, &({:cont, fun.(&1, &2)}))
    result
  end
end


# Here is the 'idiomatic' implementation of Enumerable.reduce() which Michael
# finds hard to read.
defimpl Enumerable, for: Bar do
  def reduce(_bar, {:halt, acc}, _fun) do
    {:halted, acc}
  end
  def reduce(%Bar{lst: []}, {:cont, acc}, _fun) do
    {:done, acc}
  end
  def reduce(bar, {:cont, acc}, fun) do
    {el, bar_without_el} = Bar.pop(bar)
    Enumerable.reduce(bar_without_el, fun.(el, acc), fun)
  end

  def count(_) do
    {:error, __MODULE__}
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end
end

# Here is a refactoring of the above that doesn't use multiple function heads,
# and which Michael finds easier to understand.  The one difference is that an
# outside caller can't call Enumerable.reduce(_, {:halt, _}, _).  That's stupid
# anyway.  The outside caller should always pass in :cont IMO or they're
# wasting our time.
defimpl Enumerable, for: Bar do
  def reduce(bar, {:cont, acc}, fun) do
    reduce_but_srsly_the_cmd_is_cont(bar, acc, fun)
  end

  defp reduce_but_srsly_the_cmd_is_cont(bar, acc, fun) do
    if bar.lst == [] do
      {:done, acc}

    else
      {el, bar_without_el} = Bar.pop(bar)
      {now_what, acc_after_el_is_seen} = fun.(el, acc)

      if now_what == :halt do
        {:halted, acc_after_el_is_seen} # see?  No need to recurse just to halt

      else # now_what == :cont
        reduce_but_srsly_the_cmd_is_cont(bar_without_el, acc_after_el_is_seen, fun)
      end
    end
  end

  def count(_) do
    {:error, __MODULE__}
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end
end

defimpl Collectable, for: Bar do
  def into(somebar) do
    {somebar, fn
      _bar, :halt -> nil
      bar, :done -> bar
      bar, {:cont, el} -> Bar.append(bar, el)
    end}
  end
end
