defmodule MyEnum do
  def to_list orchard do
    smart_servant = fn apple, bag ->
      new_bag = [apple | bag]
      {:cont, new_bag}
    end
    first_bag = []
    {:done, final_bag} = Enumerable.reduce(orchard, {:cont, first_bag}, smart_servant)
    final_bag |> :lists.reverse
  end

  def take(orchard, n) when n >= 0 do
    smart_servant = fn apple, _cart = {bag, i} ->
      if i == 0 do
        {:halt, bag}
      else
        new_bag = [apple | bag]
        new_cart = {new_bag, i - 1}
        {:cont, new_cart}
      end
    end
    initial_bag = []
    initial_cart = {initial_bag, n}
    {:halted, final_bag} = Enumerable.reduce(orchard, {:cont, initial_cart}, smart_servant)
    final_bag |> :lists.reverse
  end

  def filter orchard, test do
    smart_servant = fn apple, bag ->
      if test.(apple) do
        new_bag = [apple | bag]
        {:cont, new_bag}
      else
        {:cont, bag}
      end
    end
    initial_bag = []
    {:done, final_bag} = Enumerable.reduce(orchard, {:cont, initial_bag}, smart_servant)
    final_bag |> :lists.reverse
  end

  # Start with two empty saucers
  # order a pair of servants to go into each orchard and do the following:
  # - dummy should pick a fruit and show to lazy
  # - lazy should tell dummy to bring to me, take a break, and hand me his clipboard
  # if both dummies bring me a fruit
  # - make a tiny fruit basket and add to bag
  # - give clipboard to each dummy, give an empty saucer, and send back to orchard
  # if one or both dummies bring no fruit
  # - don't send back to orchard
  # - go away with my bag

  def zip(apple_orchard, kiwi_orchard) do
    bag_of_baskets = []

    apple_lazy_servant = fn apple, saucer ->
      full_saucer = [apple | saucer]
      {:suspend, full_saucer}
    end

    kiwi_lazy_servant = fn kiwi, saucer ->
      full_saucer = [kiwi | saucer]
      {:suspend, full_saucer}
    end

    apple_clipboard = fn ({command, saucer}) -> 
      Enumerable.reduce(apple_orchard, {command, saucer}, apple_lazy_servant)
    end

    kiwi_clipboard = fn ({command, saucer}) -> 
      Enumerable.reduce(kiwi_orchard, {command, saucer}, kiwi_lazy_servant)
    end

    do_zip(bag_of_baskets, [apple_clipboard, kiwi_clipboard])
  end

  def do_zip(current_bag_of_baskets, [apple_clipboard, kiwi_clipboard]) do
    apple_saucer = []
    kiwi_saucer  = []

    apple_result = apple_clipboard.({:cont, apple_saucer})
    kiwi_result  = kiwi_clipboard.({:cont, kiwi_saucer})

    apple_status = apple_result |> elem(0)
    kiwi_status  = kiwi_result |> elem(0)

    if Enum.any?([apple_status, kiwi_status], &(&1 == :done)) do
      current_bag_of_baskets |> :lists.reverse
    else
      full_apple_saucer = elem(apple_result, 1)
      full_kiwi_saucer  = elem(kiwi_result,  1)
      new_basket = {hd(full_apple_saucer), hd(full_kiwi_saucer)}
      new_bag_of_baskets = [new_basket | current_bag_of_baskets]

      clipboards = Enum.map([apple_result, kiwi_result], &(elem(&1, 2)))

      do_zip(new_bag_of_baskets, clipboards)
    end
  end
end

# Stupid simple correctness tests
IO.puts (1..5) |> MyEnum.to_list == (1..5) |> Enum.to_list
IO.puts (1..10) |> MyEnum.take(4) == (1..10) |> Enum.take(4)
IO.puts (1..10) |> MyEnum.filter(&(rem(&1, 2) == 0)) == (1..10) |> Enum.filter(&(rem(&1, 2) == 0))
IO.puts MyEnum.zip(1..5, 10..20) == Enum.zip(1..5, 10..20)
