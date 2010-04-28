# Piggly - PostgreSQL PL/pgSQL stored-procedure code coverage for Ruby

## Purpose

PL/pgSQL doesn't have much in the way of developer tools, and writing automated tests for
stored procedures can be much easier when you know what you haven't tested. Code coverage
allows you to see which parts of your code haven't been executed.

## What's Piggly?

Piggly is a tool written in Ruby to track code coverage of PostgreSQL's PL/pgSQL stored
procedures. It reports on code coverage to help you identify untested parts of your code.  You
write tests in Ruby against your stored procedures and run them with piggly.

## How Does It Work?

Piggly tracks the execution of PostgreSQL's PL/pgSQL stored procedures by recompiling
the stored procedure with instrumentation code. Basically, RAISE WARNING statements notify the
client of an execution event (e.g., a branch condition evaluating to true or false). It records
these events and generates prettified source code that is annotated with coverage details.

## Features

* Branch, block, and loop coverage analysis
* Instrumenting source-to-source compiler
* Low test execution overhead
* Reduced compilation times by use of disk caching
* Readable and easily-navigable reports (see example/piggly/reports/index.html)
* Possible to aggregate coverage across multiple runs
* Test::Unit and RSpec compatible

## Limitations

* Cannot parse nested dollar-quoted strings, eg $A$ ... $B$ ... $B$ ... $A$
* SQL statements are not instrumented, so their branches (COALESCE, WHERE-clauses, etc) aren't tracked
* Not all PL/pgSQL grammar is currently supported, but this is easily addressed

## Requirements

* [Treetop] [2]
* The [ruby-pg driver] [3], and for the time being, ActiveRecord (some workaround should be possible)

## How to Install

To install the latest release:
    $ gem install piggly

To install the latest from github:
    $ git clone git://github.com/kputnam/piggly.git
    $ cd piggly
    $ rake spec
    $ rake gem
    $ gem install pkg/*.gem --no-rdoc --no-ri

## Usage

Your stored procedures must already be loaded in the database. Your tests will automatically connect
to the database when they are loaded, or `ActiveRecord::Base.establish_connection`, is called with
no parameters to the default database. Assume the tests that exercise your stored procedures are in spec/.  

    $ cd piggly/example/
    $ ../bin/piggly 'spec/**/*_spec.rb'
    Loading 1 test files
     > Completed in 0.30 seconds
    Storing source for iterate
    Installing 1 procedures
    Compiling iterate
     > Completed in 0.50 seconds
    Clearing previous run's profile
     > Completed in 0.00 seconds
    ...........

    Finished in 0.025061 seconds

    11 examples, 0 failures
    Restoring 1 procedures
     > Completed in 0.00 seconds
    Creating index
     > Completed in 0.00 seconds
    Creating reports
    Reporting coverage for iterate
     > Completed in 0.02 seconds
    Storing coverage profile
     > Completed in 0.00 seconds

    $ ls -alh piggly/reports/index.html
    -rw-r--r-- 1 kputnam kputnam 1.4K 2010-04-28 11:21 piggly/reports/index.html

Note the compilation can be slow on the first run, but on subsequent runs it shouldn't need
to compile everything again. If a procedure is added or changed, it will be recompiled. The
report index is rebuild on each run, but the individual reports are only rebuilt if the
coverage for that procedure was updated or if the source code changed.

Piggly can also be run from Rake, with a task like:
    require 'piggly/task'

    namespace :spec do
      Piggly::Task.new(:piggly => 'db:test:prepare') do |t|
        t.libs.push 'spec'
        t.test_files = FileList['spec/**/*_spec.rb']
        t.aggregate  = false # clear previous runs

        # this can be used if piggly is frozen in a Rails application
        t.libs.concat Dir['vendor/gems/*/lib/'].sort.reverse
        t.piggly_path = Dir['vendor/gems/piggly-*/bin/piggly'].sort.last
      end
    end

    $ rake spec:piggly

## Bugs & Issues

Please report any issues on the [github tracker] [4]

## Author

* Kyle Putnam <putnam.kyle@gmail.com>

  [1]: http://github.com/relevance/rcov/
  [2]: http://github.com/nathansobo/treetop
  [3]: http://bitbucket.org/ged/ruby-pg/
  [4]: http://github.com/kputnam/piggly/issues
