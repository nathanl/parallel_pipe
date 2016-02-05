# MyEnum reimplements some functions from Enum as a learning exercise, to
# better understand Enumerable.reduce (which all the Enum functions depend on)
# To aid in understanding, we think in terms of a story.  An owner has some
# fruit orchards (enumerable collections). He has some hard-working but stupid
# servants named Enumerable.reduce (I know, it's a Finnish name).
# He has some smart but lazy servants, too (anonymous functions passed to Enumerable.reduce).
# He sends them out in pairs into his orchards to do various work. Eg:
# - "Go pick all the apples" (to_list)
# - "Go pick 20 apples" (take)
# - "Go get all the apples that are ripe" (filter)
# - "Help me build fruit baskets of one apple and one plum each - fetch one apple and one plum, and repeat until we run out of one of them" (zip)
# The stupid servant always just picks one fruit and looks to the
# smart-but-lazy servant to tell him what to do next - pick another, stop, or
# take a break and wait for the master to summon you again. The smart-but-lazy
# servant decides what goes into the fruit bag.
# If the stupid servant finds no fruit to pick, he wanders back to the master
# in confusion and hands him the fruit bag.

defmodule MyEnum do
  def to_list orchard do
    smart_servant = fn apple, bag ->
      # put the apple in the bag
      new_bag = [apple | bag]
      # order the dumb guy to pick another
      {:cont, new_bag}
    end
    first_bag = []
    # We expect the dumb servant to wander back to us when he can find no more fruit
    # :done is what he says at that point - "sorry boss, can't find no more"
    {:done, final_bag} = Enumerable.reduce(orchard, {:cont, first_bag}, smart_servant)
    final_bag |> :lists.reverse
  end

  # The smart servant works with a cart, containing a bag to put fruit in and
  # a string of knots, which show how many fruits he should collect. He
  # unties one knot each time he collects a fruit and stops when there are no
  # more to untie.
  def take(orchard, knots) when knots >= 0 do
    smart_servant = fn apple, _cart = {bag, knots} ->
      if knots == 0 do
        {:halt, bag}
      else
        new_bag = [apple | bag]
        new_cart = {new_bag, knots - 1} # untie one knot
        {:cont, new_cart}
      end
    end
    initial_bag = []
    initial_cart = {initial_bag, knots}
    # We expect the dumb servant to come back and say one of two things:
    # - :halted, meaning "uh, he told me to stop"
    # - :done, meaning "I couldn't find no more fruit"
    # Either way, we don't care - we've taken either what we wanted or as close
    # as possible
    {_halted_or_done, final_bag} = Enumerable.reduce(orchard, {:cont, initial_cart}, smart_servant)
    final_bag |> :lists.reverse
  end

  # The boss tells the smart servant some criteria for apples - "only the red
  # ones" or "only the ripe ones". The smart servant checks each one and always
  # tells the dumb servant to check for more.
  def filter orchard, criteria do
    smart_servant = fn apple, bag ->
      apple_wanted? = criteria.(apple)
      new_bag = if apple_wanted?, do: [apple | bag], else: bag
      {:cont, new_bag}
    end
    initial_bag = []
    # We expect the dumb servant to wander back to us when he can find no more fruit
    # :done is what he says at that point - "sorry boss, can't find no more"
    {:done, final_bag} = Enumerable.reduce(orchard, {:cont, initial_bag}, smart_servant)
    final_bag |> :lists.reverse
  end

  # This one is more complicated. Two orchards, two pairs of servants. 
  # The owner wants to build fruit baskets consisting of one apple and one plum.
  # The dumb servants wear whistles around their necks with which they can be
  # summoned back to work. The owner sends them into the orchards, and as long
  # as both dumb servants can bring back one fruit, he keeps summoning them to
  # pick another. 
  # As soon as one of them runs out of fruit, he tells the other one to also
  # stop working.
  def zip(apple_orchard, plum_orchard) do
    bag_of_baskets = []

    # Favoring "very clear" over DRY...
    apple_lazy_servant = fn apple, saucer ->
      full_saucer = [apple | saucer]
      {:suspend, full_saucer}
    end
    plum_lazy_servant = fn plum, saucer ->
      full_saucer = [plum | saucer]
      {:suspend, full_saucer}
    end

    # "Give me your whistle, you dolt!"
    {:suspended, nil, apple_whistle} = Enumerable.reduce(apple_orchard, {:suspend, nil}, apple_lazy_servant)
    {:suspended, nil, plum_whistle} = Enumerable.reduce(plum_orchard, {:suspend, nil}, plum_lazy_servant)

    do_zip(bag_of_baskets, [apple_whistle, plum_whistle])
  end

  def do_zip(baskets, [apple_whistle, plum_whistle]) do
    apple_saucer = []
    plum_saucer  = []

    apple_result = apple_whistle.({:cont, apple_saucer})
    plum_result  = plum_whistle.({:cont, plum_saucer})
    results      = [apple_result, plum_result]

    if Enum.any?(results, &(elem(&1, 0) == :done)) do
      # if any dumb worker is still waiting to be told what to do (eg, he can
      # find more plums but the other guy cannot find more apples), tell him to
      # :halt - go home for the day
      results
      |> Enum.filter(fn (result) ->
        elem(result, 0) == :suspended
      end)
      |> Enum.each(fn (result) ->
        whistle = elem(result, 2)
        whistle.({:halt, nil})
      end)
      baskets |> :lists.reverse
    else
      full_apple_saucer = elem(apple_result, 1)
      full_plum_saucer  = elem(plum_result,  1)
      new_basket = {hd(full_apple_saucer), hd(full_plum_saucer)}
      updated_baskets = [new_basket | baskets]

      whistles = Enum.map([apple_result, plum_result], &(elem(&1, 2)))

      do_zip(updated_baskets, whistles)
    end
  end
end

# Stupid simple correctness tests
IO.puts (1..5) |> MyEnum.to_list == (1..5) |> Enum.to_list
IO.puts (1..10) |> MyEnum.take(4) == (1..10) |> Enum.take(4)
IO.puts (1..10) |> MyEnum.filter(&(rem(&1, 2) == 0)) == (1..10) |> Enum.filter(&(rem(&1, 2) == 0))
IO.puts MyEnum.zip(1..5, 10..20) == Enum.zip(1..5, 10..20)
