class MiniTest::Unit

  STATUS_FORMAT = "\e[?7l\e[1m\e[37m(%.1fs) \e[32m%d/%d tests\e[37m, \e[36m%d assertions\e[37m, \e[31m%d errors\e[37m, \e[31m%d failures\e[37m, \e[33m%d skips \e[37m%s\e[?7h\e[0m"

  def run(args = [])
    options = process_args args

    @verbose = options[:verbose]

    filter = options[:filter] || '/./'
    filter = Regexp.new $1 if filter and filter =~ /\/(.*)\//

    seed = options[:seed]
    unless seed then
      srand
      seed = srand % 0xFFFF
    end

    srand seed

    @@out.puts "Loaded suite #{$0.sub(/\.rb$/, '')}\nStarted"

    @started_at = Time.now
    run_test_suites filter

    help = ["--seed", seed]
    help.push "--verbose" if @verbose
    help.push("--name", options[:filter].inspect) if options[:filter]

    @@out.puts "\n\nTest run options: #{help.join(" ")}\n"

    failures + errors if @test_count > 0
  rescue Interrupt
    abort "Interrupted"
  end

  def run_test_suites(filter = /./)
    @test_count, @assertion_count = 0, 0
    old_sync, @@out.sync = @@out.sync, true if @@out.respond_to? :sync=
    tests = {}
    TestCase.test_suites.each do |suite|
      suite_name = suite.name.split("::").map { |token|
        token =~ /^(test)?(.*?)(test)?$/i && $2.underscore.humanize
      }.join(" ")
      suite.test_methods.grep(filter).each do |test|
        test_name = test =~ /^(test_)?(.*)$/ && $2.underscore.humanize.downcase
        tests["#{suite_name}: #{test_name}"] = [suite, test]
      end
    end
    @test_count = tests.size
    tests.keys.each_with_index do |name, index|
      update_status(index, name)
      suite, test = tests[name]
      inst = suite.new(test)
      inst._assertions = 0
      klass, method, error = inst.run(self)
      @assertion_count += inst._assertions
      remove_status
      print_error(klass, method, error) if error
    end
    update_status(@test_count)
    @@out.sync = old_sync if @@out.respond_to? :sync=
    [@test_count, @assertion_count]
  end

  def puke(klass, method, error)
    [klass, method, error]
  end

  def print_error(klass, method, error)
    report = case error
    when MiniTest::Skip then
      @skips += 1
      "\e[30m\e[43m[SKIPPED] #{pretty_test_name(klass, method)}\e[0m\n#{pretty_location(error)}\n\e[31m#{error.message}\e[0m"
    when MiniTest::Assertion then
      @failures += 1
      "\e[37m\e[41m\e[1m[FAILURE] #{pretty_test_name(klass, method)}\e[0m\n#{pretty_location(error)}\n#{error.message}"
    else
      @errors += 1
      "\e[37m\e[41m\e[1m[ERROR] #{pretty_test_name(klass, method)}\e[0m\n#{pretty_trace(error)}"
    end
    @@out.puts "#{report}\n\n"
  end

  def pretty_test_name(klass, test)
    suite_name = klass.name.split("::").map { |token|
      token =~ /^(test)?(.*?)(test)?$/i && $2.underscore.humanize
    }.join(" ")
    test_name = test =~ /^(test_)?(.*)$/i && $2.underscore.humanize.downcase
    "#{suite_name}: #{test_name}"
  end

  def pretty_location(error)
    location = error.backtrace.detect do |line|
      line =~ %r{^#{Dir.pwd}/}
    end
    clean_trace_line("\e[1m-> ", location)
  end

  def pretty_trace(error)
    location = error.backtrace.detect do |line|
      line =~ %r{^#{Dir.pwd}/}
    end
    trace = error.backtrace.map do |line|
      prefix = line == location ? "\e[1m-> " : "   "
      clean_trace_line(prefix, line)
    end
    "\e[31m#{error.class}: #{error.message}\e[0m\n#{trace.join("\n")}"
  end

  def clean_trace_line(prefix, line)
    case line
    when %r{^#{Dir.pwd}/(.+?)/(.+)$} then "\e[37m#{prefix}[#{$1}] #{$2}\e[0m"
    when %r{^.*/gems/(.+?)/(.+)$} then "\e[36m#{prefix}[#{$1}] #{$2}\e[0m"
    when %r{^.*/rubies/(.+?)/(.+)$} then "\e[35m#{prefix}[#{$1}] #{$2}\e[0m"
    else "#{prefix}#{line}"
    end
  end

  def update_status(index, test_name = nil)
    status = STATUS_FORMAT % [Time.now - @started_at, index, @test_count, @assertion_count, @errors, @failures, @skips, test_name]
    @@out.print status
  end

  def remove_status
    @@out.print "\e[2K\r"
  end
end
