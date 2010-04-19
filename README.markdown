# Piggly - PostgreSQL PL/PgSQL stored procedure code coverage

## What's Piggly?

Piggly is like (RCov[1]) for PostgreSQL's PL/PgSQL stored procedures. It reports on code
coverage to help you identify untested parts of your code.

## Features
* Branch, block, and loop coverage analysis
* Instrumenting source-to-source compiler
* Low test execution overhead
* Reduced compilation times by use of disk caching
* Readable and easily navigable reports
* Able to aggregate coverage across multiple runs
* Test::Unit and RSpec compatible

## Limitations
* Cannot parse aggregate definitions (but helper functions are fine)
* Report generation is resource intensive and slow

## Requirements
* Stored procedures stored on the filesystem
* (Treetop[2])
* Ruby

## Usage

Assume your stored procedures are in db/proc/, and the tests that should be exercising your
stored procedures are in spec/proc/.

    $ piggly -I spec -s 'db/proc/*.sql' spec/proc/*.rb
    Loading 7 test files
    > Completed in 4.32 seconds
    Compiling 110 files
    Compiling /home/kputnam/wd/server/db/proc/roundfee.sql
    Compiling /home/kputnam/wd/server/db/proc/roundtime.sql
    Compiling /home/kputnam/wd/server/db/proc/unnest.sql
    Compiling /home/kputnam/wd/server/db/proc/unravel.sql
    ...
    > Completed in 84.17 seconds
    Installing 110 proc files
    > Completed in 1.10 seconds
    .............................................................................
    .............................................................................
    .............................................................................
    ....
    Storing coverage profile
    > Completed in 0.05 seconds
    Removing trace code
    > Completed in 0.80 seconds
    Creating index
    > Completed in 0.14 seconds
    Creating reports
    > Completed in 33.25 seconds
    > Completed in 176.79 seconds

    $ ls -alh piggly/reports/index.html
    -rw-r--r-- 1 kputnam kputnam 82K 2010-04-19 14:25 piggly/reports/index.html

Note the compilation can be slow on the first run, but on subsequent runs it shouldn't need
to be compiled again.  If a file is added or changed (based on mtime), it will be recompiled.

Piggly can also be run from Rake, with a task like:

    namespace :spec do
      Piggly::Task.new(:piggly => 'db:test:prepare') do |t|
        t.libs.push 'spec'

        t.test_files = FileList['spec/*/*_spec.rb']
        t.proc_files = 'db/{procs,functions}/*.sql'

        # this can be used if piggly is frozen in a Rails application
        t.libs.concat Dir['vendor/gems/*/lib/'].sort.reverse
        t.piggly_path = Dir['vendor/gems/piggly-*/bin/piggly'].sort.last
      end
    end

    $ rake spec:piggly

[1] http://github.com/relevance/rcov/
[2] http://github.com/nathansobo/treetop
