#!/usr/bin/env ruby

# So we have time to see this in `ps`
sleep(1)

(1..1_000_000).each do |i|
  STDOUT.puts i
  STDOUT.flush
  if i % 1_000 == 0
    STDERR.puts "produced #{i}"
  end
end
