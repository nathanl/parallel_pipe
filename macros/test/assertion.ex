#---
# Excerpted from "Metaprogramming Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/cmelixir for more book information.
#---
# Subsequently modified by me for learning purposes.
#--
defmodule Assertion do

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      # every time we do `@tests something`, add that to our lists of tests
      Module.register_attribute __MODULE__, :tests, accumulate: true
      # tell the consuming module, "before you compile, run my before_compile macro"
      @before_compile unquote(__MODULE__)
    end
  end

  # we do this last because only then does @tests have a complete list
  defmacro __before_compile__(_env) do
    quote do
      def run, do: Assertion.Test.run(@tests, __MODULE__)     
    end
  end

  defmacro test(description, do: test_block) do
    test_func = String.to_atom(description)
    quote do
      @tests {unquote(test_func), unquote(description)}
      def unquote(test_func)(), do: unquote(test_block)
    end
  end

  defmacro assert({operator, _, [lhs, rhs]}) do
    # Get the unevaluated code that was passed to the assertion so that we can use that in failure messages.
    # Eg, "you thought 5 + 5 would equal 9" instead of just "you thought 10 would equal 9"
    raw_lhs =  Macro.to_string(lhs)
    raw_rhs =  Macro.to_string(rhs)
    quote do
      Assertion.Test.assert(unquote(operator), unquote(lhs), unquote(rhs), unquote(raw_lhs), unquote(raw_rhs))
    end
  end
end

defmodule Assertion.Test do
  def run(tests, module) do                              
    Enum.each tests, fn {test_func, description} ->
      case apply(module, test_func, []) do
        :ok             -> IO.write "."
        {:fail, reason} -> IO.puts """

          ===============================================
          FAILURE: #{description}
          ===============================================
          #{reason}
          """
      end
    end
  end                                                      

  def assert(:==, lhs, rhs, _raw_lhs, _raw_rhs) when lhs == rhs do
    :ok
  end
  def assert(:==, lhs, rhs, raw_lhs, raw_rhs) do
    {:fail, """
      Expected:       #{lhs} (#{raw_lhs})
      to be equal to: #{rhs} (#{raw_rhs})
      """
    }
  end

  def assert(:>, lhs, rhs, _raw_lhs, _raw_rhs) when lhs > rhs do
    :ok
  end
  def assert(:>, lhs, rhs, raw_lhs, raw_rhs) do
    {:fail, """
      Expected:           #{lhs} (#{raw_lhs})
      to be greater than: #{rhs} (#{raw_rhs})
      """
    }
  end
end
