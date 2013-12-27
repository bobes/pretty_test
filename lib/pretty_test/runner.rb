require "minitest/unit"

module PrettyTest

  class Runner < ::MiniTest::Unit

    SKIP_FORMAT = "\e[33m[SKIPPED] %s: %s\e[0m\n%s\n%s"
    FAILURE_FORMAT = "\e[31m[FAILURE] %s: %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    ERROR_FORMAT = "\e[31m[ERROR] %s: %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    STATUS_FORMAT = "\e[2K\r\e[?7l\e[37m(%.1fs) \e[32m%d/%d tests (%d%%)\e[37m, \e[36m%d assertions\e[37m, \e[31m%d errors\e[37m, \e[31m%d failures\e[37m, \e[33m%d skips \e[37m%s\e[?7h\e[0m"

    attr_accessor :started_at, :test_count, :assertion_count, :completed, :suite_name, :test_name, :test_record

    def _run_anything(type)
      suites = TestCase.send("#{type}_suites")
      _run_suites(suites, type)
    end

    def _run_suites(suites, type)
      before_suites(suites, type)
      super
    ensure
      after_suites(suites, type)
    end

    def _run_suite(suite, type)
      before_suite(suite)
      tests = suite.send("#{type}_methods")
      tests.each do |test|
        run_test(suite, test)
      end
    ensure
      after_suite(suite, type)
    end

    def record(suite, test, assertions, time, exception)
      @test_record = TestRecord.new(suite, test, assertions, time, exception)
    end

    private

    def before_suites(suites, type)
      @started_at = Time.now
      @test_count = suites.map { |suite| suite.send("#{type}_methods").count }.sum
      @completed = 0
      @assertion_count = 0
    end

    def before_suite(suite)
      @suite_name = pretty_suite_name(suite.name)
    end

    def run_test(suite, test)
      before_test(test)
      instance = suite.new(test)
      instance._assertions = 0
      instance.run(self)
      @assertion_count += instance._assertions
    ensure
      after_test
    end

    def before_test(test)
      @test_name = pretty_test_name(test)
      remove_status
      update_status("#{suite_name}: #{test_name}")
    end

    def after_test
      @completed += 1
      case exception = test_record.exception
      when nil then pass
      when ::MiniTest::Skip then skip(exception)
      when ::MiniTest::Assertion then failure(exception)
      else error(exception)
      end
      update_status("")
    end

    def pass
    end

    def skip(exception)
      location = pretty_location(exception)
      message = exception.message.strip
      print_error SKIP_FORMAT, suite_name, test_name, message, location
    end

    def failure(exception)
      index = find_assertion_index(exception)
      trace = pretty_trace(exception, index)
      print_error FAILURE_FORMAT, suite_name, test_name, exception.class, exception.message, trace
    end

    def error(exception)
      index = find_exception_index(exception)
      trace = pretty_trace(exception, index)
      print_error ERROR_FORMAT, suite_name, test_name, exception.class, exception.message, trace
    end

    def after_suite(suite, type)
    end

    def after_suites(suites, type)
      update_status
      if errors + failures == 0
        puts "  \e[32m----- PASSED! -----\e[0m"
      else
        puts "  \e[31m----- FAILED! -----\e[0m"
      end
    end

    def pretty_suite_name(suite)
      suite = suite.dup
      suite.gsub!(/(::|_)/, " ")
      suite.gsub!(/\btest/i, "")
      suite.gsub!(/test\b/i, "")
      suite.gsub!(/\b([a-z])/i) { $1.upcase }
      suite.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
      suite.gsub!(/([a-z\d])([A-Z])/, '\1 \2')
      suite
    end

    def pretty_test_name(test)
      test = test.dup
      test.gsub!(/^test_/, "")
      test.gsub!(/_+/, " ")
      test
    end

    def pretty_location(e)
      path, line = location(e)
      clean_trace_line("\e[1m-> ", path, line)
    end

    def find_assertion_index(error)
      index = error.backtrace.rindex { |trace| trace =~ /:in .(assert|refute|flunk|pass|fail|raise|must|wont)/ }
      index ? index + 1 : find_exception_index(error)
    end

    def find_exception_index(error)
      error.backtrace.index { |trace| trace.index(Dir.pwd) }
    end

    def pretty_trace(error, location_index)
      lines = []
      error.backtrace.each_with_index do |trace, index|
        prefix = index == location_index ? "\e[1m-> " : "   "
        trace_file, trace_line, trace_method = trace.split(":", 3)
        lines << clean_trace_line(prefix, trace_file, trace_line, trace_method)
      end
      lines.compact.join("\n")
    end

    def clean_trace_line(prefix, path, line, method = nil)
      case path
      when %r{^#{Dir.pwd}/([^/]+)/(.+)$} then "\e[37m#{prefix}[#{$1}] #{$2}:#{line} #{method}\e[0m"
      when %r{^.*/(ruby-[^/]+)/(bin/.+)$} then "\e[35m#{prefix}[#{$1}] #{$2}:#{line} #{method}\e[0m"
      when %r{^.*/gems/(minitap|minitest)-.+/(.+)$} then nil
      when %r{^.*/gems/([^/]+)/(.+)$} then "\e[36m#{prefix}[#{$1}] #{$2}:#{line} #{method}\e[0m"
      else "#{prefix}#{path}:#{line}\e[0m"
      end
    end

    def print_error(format, *args)
      remove_status
      puts format % args
      puts
    end

    def update_status(message = "")
      running_time = Time.now - started_at
      progress = 100.0 * completed / test_count
      print STATUS_FORMAT % [running_time, completed, test_count, progress, assertion_count, errors, failures, skips, message]
    end

    def remove_status
      print "\e[2K\r"
    end

    class TestRecord < Struct.new(:suite, :test, :assertions, :time, :exception)
    end
  end
end
