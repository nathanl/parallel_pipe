#!/usr/bin/env ruby

STDERR.puts "starting up discarder"

# So we have time to see this in `ps`
sleep(2)

while thing = STDIN.gets
  sleep(100)
  STDERR.puts "discarder got something"
  int = Integer(thing.chomp)
  if int.even?
    STDERR.puts "#{int} is even"
    STDOUT.puts int
  else
    STDERR.puts "#{int} is odd"
  end
end
