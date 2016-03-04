defmodule NumToStringMaps do
  @range 1..20_000
  @map (@range |> Enum.map(fn (i) -> {i, Integer.to_string(i) } end) |> Enum.into(%{}))

  def num_to_string(i) do
    @map[i]
  end

  def lookup_all do
    Enum.map(@range, fn (i) ->
      num_to_string(i)
    end)
  end
end
