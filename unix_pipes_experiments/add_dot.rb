#!/usr/bin/env ruby

# So we have time to see this in `ps`
sleep(2)

# Add a dot to every line of standard input
while thing = STDIN.gets
  STDOUT.puts "#{thing.chomp}."
end
