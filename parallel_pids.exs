# NOT parallel
defmodule AddDots do
  def go(input) do
    :timer.sleep(1000)
    IO.inspect self
    "#{input}."
  end
end

"hi" |> AddDots.go |> AddDots.go |> AddDots.go |> IO.inspect

