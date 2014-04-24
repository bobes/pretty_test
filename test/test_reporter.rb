require "stringio"
require "pretty_test/reporter"

class TestReporter

  def self.run
    new.run
  end

  def run
    output = StringIO.new("")
    reporter = PrettyTest::Reporter.new(output)

    klass = Class.new(::Minitest::Test) do

      def self.name
        "SomeTest"
      end

      def test_pass
        assert true
      end

      def test_fail
        assert false
      end

      def test_error
        raise "qwe"
      end
    end

    reporter.start
    klass.run reporter, {}
    reporter.report
    puts output.string
  end
end

TestReporter.run
