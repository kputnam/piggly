# Piggly - PostgreSQL PL/pgSQL stored-procedure code coverage for Ruby

## Purpose

PL/pgSQL doesn't have much in the way of developer tools, and writing automated tests for
stored procedures can be much easier when you know what you haven't tested. Code coverage
allows you to see which parts of your code haven't been executed.

## What's Piggly?

Piggly is a tool (written in Ruby) to track code coverage of PostgreSQL PL/pgSQL stored
procedures. It reports on code coverage to help you identify untested parts of your code.
You write tests in Ruby against your stored procedures and run them with piggly.

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
* Readable and easily-navigable reports (see [example] [5])
* Possible to aggregate coverage across multiple runs
* Test::Unit and RSpec compatible

## Limitations

* Cannot parse nested dollar-quoted strings, eg $A$ ... $B$ ... $B$ ... $A$
* SQL statements are not instrumented, so their branches (COALESCE, WHERE-clauses, etc) aren't tracked
* Not all PL/pgSQL grammar is currently supported, but this is easily addressed

## Requirements

* [Treetop] [2]
* The [ruby-pg driver] [3], and to run the examples, ActiveRecord

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

Your stored procedures must already be loaded in the database. Your tests should automatically connect
to the database when they are loaded, or `ActiveRecord::Base.establish_connection`, will be called with
no parameters to connect the default database. Assume your tests are in spec/.  

    $ cd piggly
    $ cat example/README
    ...

    $ ./example/run-tests
    compiling 5 procedures
    Compiling scramble
    Compiling scramble
    Compiling numberedargs
    Compiling snippets
    Compiling iterate
    tracing 5 procedures
    Loaded suite /home/kputnam/wd/piggly/example/test/iterate_test
    Started
    ......
    Finished in 0.199236 seconds.

    6 tests, 6 assertions, 0 failures, 0 errors, 0 skips

    Test run options: --seed 25290
    clearing previous coverage
    storing coverage profile
    creating index
    creating reports
    reporting coverage for scramble
    reporting coverage for scramble
    reporting coverage for numberedargs
    reporting coverage for snippets
    reporting coverage for iterate: +0.0% block, +0.0% branch, +0.0% loop
    restoring 5 procedures
    OK, view /home/kputnam/wd/piggly/example/piggly/reports/index.html

    $ ls -alh piggly/reports/index.html
    -rw-r--r-- 1 kputnam kputnam 1.4K 2010-04-28 11:21 piggly/reports/index.html

Note the compilation can be slow on the first run, but on subsequent runs it shouldn't need
to compile everything again. If a procedure is added or changed, it will be recompiled. The
report index is rebuilt on each run, but the individual reports are only rebuilt if the
coverage for that procedure was updated or if the source code changed.

## Bugs & Issues

Please report any issues on the [github tracker] [4]

  [1]: http://github.com/relevance/rcov/
  [2]: http://github.com/nathansobo/treetop
  [3]: http://bitbucket.org/ged/ruby-pg/
  [4]: http://github.com/kputnam/piggly/issues
  [5]: http://kputnam.github.com/piggly/reports/index.html
