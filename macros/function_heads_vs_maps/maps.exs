defmodule NumToString2 do
  @range 1..10_000
  @map @range |> Enum.map(fn (i) -> {i, Integer.to_string(i) } end) |> Enum.into(%{})
  def num_to_string(i) do
    @map[i]
  end

  def lookup_all do
    Enum.each(@range, fn (i) ->
      num_to_string(i)
    end)
  end
end
