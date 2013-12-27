require "pretty_test/runner"

MiniTest::Unit.runner = PrettyTest::Runner.new if STDOUT.tty?
