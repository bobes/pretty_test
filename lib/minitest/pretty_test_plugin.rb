module Minitest

  def self.plugin_pretty_test_init(options)
    return unless STDOUT.tty?
    reporter.reporters.delete_if do |r|
      Minitest::ProgressReporter === r || Minitest::SummaryReporter === r
    end
    reporter << PrettyTest::Reporter.new(options)
  end
end
