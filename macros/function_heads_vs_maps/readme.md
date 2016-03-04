"Metaprogramming Elixir" talks about how String.Unicode reads a bunch of text data and defines a separate function head for each character we might want to upcase. It says this leans on the Erlang VM's pattern matching prowess and implies (I think) that it's more performant than it would be to create a lower -> upper map at compile time and consult it at runtime.

Since I understand maps (at least hash-table-based ones) to be O(1) lookup time, this doesn't make sense to me. The goal here is to try the two approaches and compare memory usage and speed.

Findings:

- The one with many function heads is much slower to run as an `.exs`. Presumably most of that time is compilation. Maybe it's faster at run time?
- `elixirc [filename]` is in fact much slower for the function heads version. For large enough range values, I waited a couple of minutes and killed the compilation process. For small enough ranges that it could finish, opening `iex` and trying `NumToString1.lookup_all` vs `NumToString2.lookup_all`, I couldn't subjectively see any difference in speed.

Want to test some more...

See also: http://stackoverflow.com/questions/28719263/elixir-erlang-fast-lookup-with-static-table
iee pt. E 
Athens, GA 30606also: http://stackoverflow.com/questions/28719263/elixir-erlang-fast-lookup-with-static-table

https://github.com/elixir-lang/elixir/blob/5f276918ac6505693c7adca31d95e24d480f0869/lib/elixir/unicode/unicode.ex#L71-L79

http://stackoverflow.com/questions/35677865/is-map-lookup-in-elixir-o1
