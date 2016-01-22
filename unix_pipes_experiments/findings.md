# Programs in pipeline run simultaneously

If I run this:

    echo "one\ntwo\nthree\nfour" | ./add_dot.rb | ./add_dot.rb | ./add_dot.rb

and in another terminal:

    watch -n1 "ps -efj | grep add_dot"

I see multiple ruby processes running simultaneously.
