module Piggly
  module Command

    #
    # This command handles all the setup and teardown for running Ruby tests, that can
    # otherwise be accomplished in a more manual fashion, using the other commands. It
    # assumes that the test files will automatically establish a connection to the correct
    # database when they are loaded (this is the case for Rails).
    #
    module Test
      class << self

        def main(argv)
          benchmark do
            tests, filters = parse_options(argv)

            # don't let rspec get these when loading spec files
            ARGV.clear

            load_tests(tests)
            Piggly::Command.connect_to_database

            procedures = dump_procedures(filters)

            if procedures.empty?
              abort "No stored procedures in the database#{' matched your criteria' if filters.any?}"
            end

            result =
              begin
                trace(procedures)
                clear_coverage
                execute_tests
              ensure
                untrace(procedures)
              end

            create_index(procedures)
            create_reports(procedures)
            store_coverage

            exit! result # avoid running tests again
          end
        end

      private

        def benchmark
          start = Time.now
          value = yield
          puts " > Completed in #{'%0.2f' % (Time.now - start)} seconds"
          return value
        end

        #
        # Parses command-line options
        #
        def parse_options(argv)
          filters = []

          opts = OptionParser.new do |opts|
            opts.on("-I", "--include PATHS", "Prepend paths to $LOAD_PATH (colon separated list)", &Command.method(:opt_include_path))
            opts.on("-o", "--report-root PATH", "Report output directory", &Command.method(:opt_report_root))
            opts.on("-c", "--cache-root PATH", "Local cache directory", &Command.method(:opt_cache_root))

            opts.on("-n", "--name PATTERN", "Trace stored procedures matching PATTERN") do |opt|
              if m = opt.match(%r{^/(.+)/$})
                filters << lambda{|p| p.name.match(m.captures.first) }
              else
                filters << lambda{|p| p.name === opt }
              end
            end
       
            opts.on("-a", "--aggregate", "Aggregate data from the previous run", &Command.method(:opt_aggregate))
            opts.on("-V", "--version", "Show version", &Command.method(:opt_version))
            opts.on("-h", "--help", "Show this message") do
              puts opts
              exit! 0
            end
          end

          begin
            opts.parse! argv
            raise OptionParser::MissingArgument, "no tests specified" if argv.empty?
          rescue OptionParser::InvalidOption,
                 OptionParser::InvalidArgument,
                 OptionParser::MissingArgument
            puts opts
            puts
            puts $!

            exit! 1
          end

          test_paths = argv.map{|p| Dir[p] }.flatten.sort

          return test_paths, filters
        end

        def load_tests(tests)
          puts "Loading #{tests.size} test files"
          benchmark { tests.each{|file| load file }}
        end

        #
        # Writes all stored procedures in the database to disk
        #
        def dump_procedures(filters)
          Piggly::Command::Trace.dump_procedures(filters)
        end

        #
        # Compiles all the stored procedures on disk and installs them
        #
        def trace(procedures)
          benchmark { Piggly::Command::Trace.trace(procedures) }
        end

        def clear_coverage
          Piggly::Command::Report.clear_coverage
        end

        def execute_tests
          if defined? ::Test::Unit::AutoRunner
            ::Test::Unit::AutoRunner.run
          elsif defined? ::RSpec::Core
            ::Rspec::Core::Runner.run(ARGV, $stderr, $stdout)
          elsif defined? ::Spec::Runner
            ::Spec::Runner.run
          elsif defined? ::MiniTest::Unit
            ::MiniTest::Unit.new.run(ARGV)
          else
            raise "Neither Test::Unit, MiniTest, nor RSpec were detected"
          end
        end

        def store_coverage
          benchmark { Piggly::Command::Report.store_coverage }
        end

        def untrace(procedures)
          benchmark { Piggly::Command::Untrace.untrace(procedures) }
        end

        def create_index(procedures)
          benchmark { Piggly::Command::Report.create_index(procedures) }
        end

        def create_reports(procedures)
          benchmark { Piggly::Command::Report.create_reports(procedures) }
        end

      end
    end
  end
end
