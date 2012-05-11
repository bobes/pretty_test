# Pretty Test

`pretty_test` is a Ruby gem that will make output from your
[minitest](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/minitest/unit/rdoc/index.html)
tests pretty and useful.

## The problem

There are only two things I want to see *while* running a suite of tests: progress and failed tests.

[minitest](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/minitest/unit/rdoc/index.html)
prints dots for passed tests and Fs for failed tests - not very useful. If you want to know *which* tests failed and *why*, you have to wait until the whole suite is finished. This kind of feedback is painfully slow.

[Turn](https://github.com/TwP/turn) with the default settings brings a huge improvement by printing failed test details immediately. But it also prints one line for every passed test. So you'll often get just a glimpse of a failed test stack trace immediately replaced by a fast-scrolling list of passed tests. *(I know there are other output formats in turn but I haven't found any of them very useful.)*

## The solution

With `pretty_test` you'll get

* number of passed and failed tests, number of passed assertions,
* name of currently running test,
* error information and a colorised stack trace for every failed test,
* highlighted line of code that most likely caused the failure.

And all of this in real time.

## Install

All you need to do is to add `pretty_test` to your Gemfile:

    group :test do
      gem "pretty_test"
      # ...
    end

and enjoy pretty and useful test output.
