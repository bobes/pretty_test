require "pretty_test/version"
require "pretty_test/tap"

MiniTest::Unit.runner = PrettyTest::Tap.new if STDOUT.tty?
