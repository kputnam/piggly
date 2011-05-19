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
          index   = Dumper::Index.new

          Command::connect_to_database
          procedures = dump_procedures(filters, index)

          if procedures.empty?
            abort "No stored procedures in the cache#{' matched your criteria' if filters.any?}"
          end

          trace(procedures)
        end

        #
        # Writes all stored procedures in the database to disk, then returns a list of Procedure
        # values that satisfy at least one of the given filters
        #
        def dump_procedures(filters, index)
          index.update(Dumper::ReifiedProcedure.all)

          if filters.empty?
            index.procedures
          else
            filters.inject(Set.new){|set, filter| set | index.procedures.select(&filter) }
          end
        end

        #
        # Compiles all the stored procedures on disk and installs them
        #
        def trace(procedures, profile)
          puts "Installing #{procedures.size} procedures"

          # force parser to load before we start forking
          Parser.parser

          queue = Util::ProcessQueue.new
          procedures.each{|p| queue.add { Compiler::Trace.cache(p, p.oid) }}
          queue.execute

          Installer.install_trace_support(profile, Config)

          procedures.each do |p|
            begin
              Installer.trace(p, profile)
            rescue Parser::Failure
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
