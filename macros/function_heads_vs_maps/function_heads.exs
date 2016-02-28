defmodule NumToString1 do
  @range 1..10_000
  Enum.each(@range, fn (i) -> 
    def num_to_string(unquote(i)) do
      Integer.to_string(unquote(i))
    end
  end)

  def lookup_all do
    Enum.each(@range, fn (i) ->
      num_to_string(i)
    end)
  end
end
