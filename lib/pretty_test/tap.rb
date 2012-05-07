require "minitap"
module PrettyTest

  class Tap < ::MiniTest::MiniTap

    SKIP_FORMAT = "\e[33m[SKIPPED] %s: %s\e[0m\n%s\n%s"
    FAILURE_FORMAT = "\e[31m[FAILURE] %s: %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    ERROR_FORMAT = "\e[31m[ERROR] %s: %s\e[0m\n\e[31m%s: %s\e[0m\n%s"
    STATUS_FORMAT = "\e[2K\r\e[?7l\e[37m(%.1fs) \e[32m%d/%d tests\e[37m, \e[36m%d assertions\e[37m, \e[31m%d errors\e[37m, \e[31m%d failures\e[37m, \e[33m%d skips \e[37m%s\e[?7h\e[0m"

    attr_accessor :started_at, :progress, :suite_name, :test_name

    def tapout_before_suites(suites, type)
      @started_at = Time.now
      @progress = 0
    end

    def tapout_before_suite(suite)
      @suite_name = pretty_suite_name(suite.name)
    end

    def tapout_before_test(suite, test)
      @test_name = pretty_test_name(test)
      remove_status
      update_status("#{suite_name}: #{test_name}")
    end

    def tapout_pass(suite, test, test_runner)
      @progress += 1
      update_status("")
    end

    def tapout_skip(suite, test, test_runner)
      @progress += 1
      error = test_runner.exception
      test_name = pretty_test_name(test)
      location = pretty_location(error)
      message = error.message.strip
      print_error SKIP_FORMAT, suite_name, test_name, message, location
    end

    def tapout_failure(suite, test, test_runner)
      @progress += 1
      error = test_runner.exception
      test_name = pretty_test_name(test)
      index = find_assertion_index(error)
      trace = pretty_trace(error, index)
      print_error FAILURE_FORMAT, suite_name, test_name, error.class, error.message, trace
    end

    def tapout_error(suite, test, test_runner)
      @progress += 1
      error = test_runner.exception
      test_name = pretty_test_name(test)
      index = find_exception_index(error)
      trace = pretty_trace(error, index)
      print_error ERROR_FORMAT, suite_name, test_name, error.class, error.message, trace
    end

    def tapout_after_suites(suites, type)
      update_status
      puts "\n\nSuite seed: #{options[:seed]}\n\n"
      if errors + failures == 0
        puts "\e[32m----- PASSED! -----\e[0m"
      else
        puts "\e[31m----- FAILED! -----\e[0m"
      end
    end

    def tapout_(suite, test, test_runner)
      remove_status
      puts "\n\e[31mCould not run #{suite}##{test} for an unknown reason\e[0m\n"
      puts
    end

    protected

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
      else "#{prefix}#{path}:#{line}"
      end
    end

    def print_error(format, *args)
      remove_status
      puts format % args
      puts
    end

    def update_status(message = "")
      print STATUS_FORMAT % [Time.now - started_at, progress, test_count, assertion_count, errors, failures, skips, message]
    end

    def remove_status
      print "\e[2K\r"
    end
  end
end
