# Programs in pipeline run simultaneously

If I run this:

    echo "one\ntwo\nthree\nfour" | ./add_dot.rb | ./add_dot.rb | ./add_dot.rb

and in another terminal:

    watch -n1 "ps -efj | grep add_dot"

I see multiple ruby processes running simultaneously.

When a process tries to write to a pipe that's closed, I think that bash sends it `kill -PIPE`. These both die gracefully; the second gives incremental output.

    ruby -e '(1..10).each {|i| sleep(0.1); puts i}' | head -3

    ruby -e 'Signal.trap("PIPE", "EXIT");(1..10).each {|i| sleep(0.1); puts i; STDOUT.flush }' | head -3
