# Piggly - PostgreSQL PL/pgSQL stored-procedure code coverage for Ruby

## What's Piggly?
Piggly is like [RCov] [1] for PostgreSQL's PL/pgSQL stored procedures. It reports on code
coverage to help you identify untested parts of your code.

## Features
* Branch, block, and loop coverage analysis
* Instrumenting source-to-source compiler
* Low test execution overhead
* Reduced compilation times by use of disk caching
* Readable and easily-navigable reports (see example/piggly/reports/index.html)
* Possible to aggregate coverage across multiple runs
* Test::Unit and RSpec compatible

## Limitations
* Cannot parse aggregate definitions (but helper functions are fine)
* Cannot parse nested dollar-quoted strings, eg $A$ ... $B$ ... $B$ ... $A$
* Report generation is resource intensive and slow
* SQL statements are not instrumented, so their branches (COALESCE, WHERE-clauses, etc) aren't tracked

## Requirements
* [Treetop] [2]
* Stored procedures stored on the filesystem, defined with "CREATE OR REPLACE FUNCTION ..."
* The [ruby-pg driver] [3], and for the time being, ActiveRecord (some workaround should be possible)

## How to Install
    $ gem install piggly

## Usage
Assume your stored procedures are in proc/, and the tests that should be exercising your
stored procedures are in spec/.

    $ cd piggly/example/
    $ ../bin/piggly -s 'proc/*.sql' 'spec/**/*_spec.rb'
    Loading 1 test files
     > Completed in 0.30 seconds
    Compiling 1 files
    Compiling /home/kputnam/wd/piggly/example/proc/iterate.sql
     > Completed in 0.09 seconds
    Installing 1 proc files
     > Completed in 0.02 seconds
    Clearing previous run's profile
     > Completed in 0.00 seconds
    ...........

    Finished in 0.025061 seconds

    11 examples, 0 failures
    Storing coverage profile
     > Completed in 0.00 seconds
    Removing trace code
     > Completed in 0.00 seconds
    Creating index
     > Completed in 0.00 seconds
    Creating reports
     > Completed in 0.02 seconds
     > Completed in 0.65 seconds

    $ ls -alh piggly/reports/index.html
    -rw-r--r-- 1 kputnam kputnam 1.3K 2010-04-19 14:25 piggly/reports/index.html

Note the compilation can be slow on the first run, but on subsequent runs it shouldn't need
to be compiled again. If a file is added or changed (based on mtime), it will be recompiled.

Piggly can also be run from Rake, with a task like:
    require 'piggly/task'

    namespace :spec do
      Piggly::Task.new(:piggly => 'db:test:prepare') do |t|
        t.libs.push 'spec'

        t.test_files = FileList['spec/**/*_spec.rb']
        t.proc_files = FileList['proc/*.sql']

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
