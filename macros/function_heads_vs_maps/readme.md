"Metaprogramming Elixir" (Chris McCord) talks about how `String.Unicode` [reads a text file of unicode characters at compile time and defines a separate function head for each character we might want to upcase](https://github.com/elixir-lang/elixir/blob/5f276918ac6505693c7adca31d95e24d480f0869/lib/elixir/unicode/unicode.ex#L71-L79). It says this leans on the Erlang VM's pattern matching prowess and implies (I think) that it's more performant than it would be to create a lower -> upper map at compile time and consult it at runtime.

Similarly, McCord in advocates this approach for some example code that looks up I18n keys.

> By generating function heads for each translation mapping, we again let the Virtual Machine take over for fast lookup.

Although defining multiple function heads is idiomatic Elixir, this seemed odd to me. I've heard that the Erlang VM is really fast at pattern matching and hence at finding the right function for a given set of arguments. But if the "pattern" is a simple value, it seemed that it could just as easily be the key in a map.

[Maybe making lots of function heads is better because maps are slow in Elixir?](http://stackoverflow.com/questions/35677865/is-map-lookup-in-elixir-o1) But I was told they [got a lot faster](https://gist.github.com/BinaryMuse/bb9f2cbf692e6cfa4841) since Erlang 18 was released.

I decided to test compile and run times for these two simplistic modules:

    !#elixir
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
  
    # vs

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

My method was this:

- `rm *.beam && time elixirc function_heads.exs && time elixir go_fh.exs && time elixirc maps.exs && time elixir go_maps.exs`, meaning:
  - `time elixirc` to measure compilation time for each module (after deleting the `.beam` files from last run)
  - `time elixir go_fh.exs` and `time elixir go_maps.exs`, which are two scripts that just output the result of the module's `lookup_all` function
- Double the size of the range and do it again
- Try all of the above on the latest Erlang/Elixir and an older one.

Not super scientific, especially since I just did each run once (I'm impatient) and was doing other stuff on the computer while I waited. But the results were still interesting.

**Elixir 1.1.1 / Erlang 17**

    | Entries | map compile | map run | fh compile | fh run |
    |-------------------------------------------------------|
    |020,000  |   01.3s     | 000.9s  | 019.0s     | 0.4s   |
    |040,000  |   02.1s     | 002.5s  | 068.7s     | 0.4s   |
    |080,000  |   04.0s     | 008.5s  | 229.9s     | 0.4s   |
    |160,000  |   08.4s     | 033.5s  | 876.7s     | 0.6s   |
    |320,000  |   16.2s     | 140.0s  | no thx     | nope   |

The "no thx" is where I got too impatient to try that. :D

**Elixir 1.2.3 / Erlang 18**

    | Entries | map compile | map run | fh compile | fh run |
    |-------------------------------------------------------|
    |020,000  |   01.2s     | 000.4s  | 018.7s     | 0.4s   |
    |040,000  |   02.0s     | 000.4s  | 065.6s     | 0.4s   |
    |080,000  |   03.6s     | 000.5s  | 237.8s     | 0.5s   |
    |160,000  |   07.2s     | 000.5s  | 931.6s     | 0.6s   |
    |320,000  |   14.4s     | 000.7s  | no thx     | nope   |

Here's how it looks to me: with older versions of Elixr and Erlang, compilation times seemed to grow roughly linearly for the map lookup version and worse than linearly for the function head version. But the runtime speed for the function head version was much better, maybe `O(log N)`, where the runtime speed for the map version was worse than `O(N)`. **The compile-time hit seemed to be worth the runtime speedup**.

But with the latest versions of Elixir and Erlang, **the runtime speeds were the same, but the map version was dramatically faster to compile**.

Some caveats on these results:

- This wasn't very scientific
- This is simple match, not like "find a function head that will accept a map where `:pizza_flavors` is a list"
- I don't know beans about the Erlang VM

But with those caveats, it seems like simple lookup cases in recent versions of Erlang would be better served by a map lookup than by defining many function heads.

Am I wrong?

See also:
- http://stackoverflow.com/questions/28719263/elixir-erlang-fast-lookup-with-static-table
- http://stackoverflow.com/questions/35677865/is-map-lookup-in-elixir-o1
