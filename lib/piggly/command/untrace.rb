module Piggly
  module Command

    # * install original stored procedures
    module Untrace
      class << self

        def main(argv)
          filters = parse_options(argv)

          Command.connect_to_database

          index = Dumper::Index.new
          procedures = find_procedures(filters)

          if procedures.empty?
            abort "No stored procedures in the cache#{' matched your criteria' if filters.any?}"
          end

          untrace(procedures)
        end

        #
        # Restores database procedures from file cache
        #
        def untrace(procedures)
          puts "Restoring #{procedures.size} procedures"
          procedures.each{|p| Installer.untrace(p) }
          Installer.uninstall_trace_support
        end

        #
        # Returns a list of Procedure values that satisfy at least one of the given filters
        #
        def find_procedures(filters, index)
          if filters.empty?
            index.procedures
          else
            filters.inject(Set.new){|set, filter| set | index.procedures.select(&filter) }
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

            opts.on("-n", "--name PATTERN", "Untrace stored procedures matching PATTERN") do |opt|
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
