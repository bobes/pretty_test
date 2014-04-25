require "minitest"

module PrettyTest

  class Reporter < ::Minitest::AbstractReporter

    SKIP_FORMAT = "\e[33m[SKIPPED] %s\e[0m\n%s\n%s"
    FAILURE_FORMAT = "\e[31m[FAILURE] %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    ERROR_FORMAT = "\e[31m[ERROR] %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    STATUS_FORMAT = "\e[2K\r\e[?7l\e[37m(%.1fs) \e[32m%d/%d tests (%d%%)\e[37m, \e[36m%d assertions\e[37m, \e[31m%d errors\e[37m, \e[31m%d failures\e[37m, \e[33m%d skips\e[?7h\e[0m"

    attr_accessor :io, :started_at, :tests, :assertions, :completed, :failures, :errors, :skips

    def initialize(options = {})
      super()

      self.io = options[:io] || $stdout

      self.started_at = nil
      self.completed = 0
      self.assertions = 0
      self.failures = 0
      self.errors = 0
      self.skips = 0
    end

    def start
      self.started_at = Time.now
      suites = ::Minitest::Runnable.runnables
      self.tests = 0
      suites.each do |suite|
        self.tests += suite.runnable_methods.count
      end
    end

    def record(result)
      super
      test_name = "#{result.class.name}##{result.name}"
      @completed += 1
      @assertions += result.assertions
      case exception = result.failure
      when nil then pass
      when ::MiniTest::Skip then skip(test_name, exception)
      when ::MiniTest::Assertion then failure(test_name, exception)
      else error(test_name, exception)
      end
      update_status
    end

    def report
      if tests > 0
        update_status
      end
      if errors + failures == 0
        io.puts "  \e[32m----- PASSED! -----\e[0m"
      else
        io.puts "  \e[31m----- FAILED! -----\e[0m"
      end
    end

    def passed?
      true
    end

    def pass
    end

    def skip(test_name, exception)
      self.skips += 1
      index = find_assertion_index(exception)
      trace = pretty_trace(exception, index)
      print_error SKIP_FORMAT, test_name, exception.message, trace
    end

    def failure(test_name, exception)
      self.failures += 1
      index = find_assertion_index(exception)
      trace = pretty_trace(exception, index)
      print_error FAILURE_FORMAT, test_name, exception.class, exception.message, trace
    end

    def error(test_name, exception)
      self.errors += 1
      index = find_exception_index(exception)
      trace = pretty_trace(exception, index)
      print_error ERROR_FORMAT, test_name, exception.class, exception.message, trace
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
      backtrace = error.backtrace
      entry_point = backtrace.reverse.detect { |trace| trace.starts_with?(Dir.pwd) }
      backtrace.each_with_index do |trace, index|
        prefix = index == location_index ? "\e[1m-> " : "   "
        trace_file, trace_line, trace_method = trace.split(":", 3)
        lines << clean_trace_line(prefix, trace_file, trace_line, trace_method)
        break if trace == entry_point
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
      io.puts format % args
      io.puts
    end

    def update_status
      running_time = Time.now - started_at
      progress = 100.0 * completed / tests
      io.print STATUS_FORMAT % [running_time, completed, tests, progress, assertions, errors, failures, skips]
    end

    def remove_status
      io.print "\e[2K\r"
    end
  end
end
