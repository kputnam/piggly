module Piggly
  module Command

    #
    # This command connects to the database, dumps all stored procedures, compiles them
    # with instrumentation code, and finally installs the instrumented code.
    #
    module Trace
      class << self

        def main(argv)
          filters = parse_options(argv)

          Piggly::Command::connect_to_database
          procedures = dump_procedures(filters)

          if procedures.empty?
            abort "No stored procedures in the cache#{' matched your criteria' if filters.any?}"
          end

          trace(procedures)
        end

        #
        # Writes all stored procedures in the database to disk, then returns a list of Procedure
        # values that satisfy at least one of the given filters
        #
        def dump_procedures(filters)
          index = Piggly::Dumper::Index.instance
          index.update(Piggly::Dumper::ReifiedProcedure.all)

          if filters.empty?
            index.procedures
          else
            filters.inject(Set.new){|set, filter| set | index.procedures.select(&filter) }
          end
        end

        #
        # Compiles all the stored procedures on disk and installs them
        #
        def trace(procedures)
          puts "Installing #{procedures.size} procedures"

          # force parser to load before we start forking
          Piggly::Parser.parser

          queue = Piggly::Util::ProcessQueue.new
          procedures.each{|p| queue.add { Piggly::Compiler::Trace.cache(p, p.oid) }}
          queue.execute

          Piggly::Installer.install_trace_support

          procedures.each do |p|
            begin
              Piggly::Installer.trace(p)
            rescue Piggly::Parser::Failure
              puts $!
            end
          end
        end

        #
        # Parses command-line options
        #
        def parse_options(argv)
          filters = []

          opts = OptionParser.new do |opts|
            opts.on("-c", "--cache-root PATH", "Local cache directory", &Command.method(:opt_cache_root))
            opts.on("-k", "--cache-key MODE", "Use MODE [name|signature|oid] as cache key for each procedure", &Command.method(:opt_cache_key))
            opts.on("-d", "--database PATH", "Read 'piggly' database adapter settings from YAML file at PATH", &Command.method(:opt_database))

            opts.on("-n", "--name PATTERN", "Trace stored procedures matching PATTERN") do |opt|
              if m = opt.match(%r{^/(.+)/$})
                filters << lambda{|p| p.name.match(m.captures.first) }
              else
                filters << lambda{|p| p.name === opt }
              end
            end

            opts.on("-V", "--version", "Show version", &Command.method(:opt_version))
            opts.on("-h", "--help", "Show this message") do
              puts opts
              exit!
            end
          end

          begin
            opts.parse! argv
          rescue OptionParser::InvalidOption,
                 OptionParser::InvalidArgument,
                 OptionParser::MissingArgument
            puts opts
            puts
            puts $!

            exit! 1
          end

          filters
        end

      end
    end
  end
end
