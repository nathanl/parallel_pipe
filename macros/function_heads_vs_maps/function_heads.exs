defmodule NumToStringFh do
  @range 1..20_000
  Enum.each(@range, fn (i) -> 
    def num_to_string(unquote(i)) do
      Integer.to_string(unquote(i))
    end
  end)

  def lookup_all do
    Enum.map(@range, fn (i) ->
      num_to_string(i)
    end)
  end
end
