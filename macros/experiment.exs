defmodule MyMacros do
  defmacro test(description, block) do
    quote do
      if unquote(block[:do]) do
        IO.puts "."
      else
        raise "test failed: #{unquote(description)}"
      end
    end
  end
end
