module Piggly
  module Command

    class Untrace < Base
    end

    class << Untrace
      def main(argv)
        config      = configure(argv)
        index       = Dumper::Index.new(config)
        connection  = connect(config)
        procedures  = filter(config, index)

        if procedures.empty?
          if config.filters.empty?
            abort "no stored procedures in the cache"
          else
            abort "no stored procedures in the cache matched your criteria"
          end
        end

        untrace(Installer.new(config, connection), procedures)
      end

      #
      # Restores database procedures from file cache
      #
      def untrace(installer, procedures)
        puts "restoring #{procedures.size} procedures"
        installer.uninstall(procedures)
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
      def configure(argv, config = Config.new)
        p = OptionParser.new do |o|
          o.on("-c", "--cache-root PATH", "local cache directory", &o_cache_root(config))
          o.on("-d", "--database PATH",   "read 'piggly' database adapter settings from YAML file", &o_database_yml(config))
          o.on("-k", "--connection NAME", "use connection adapter NAME", &o_connection_name(config))
          o.on("-n", "--name PATTERN",    "trace stored procedures matching PATTERN", &o_filter(config))
          o.on("-V", "--version",         "show version", &o_version(config))
          o.on("-h", "--help",            "show this message") { abort o.to_s }
        end

        begin
          p.parse! argv
          config
        rescue OptionParser::InvalidOption,
               OptionParser::InvalidArgument,
               OptionParser::MissingArgument
          puts p
          puts
          puts $!
          exit! 1
        end
      end

    end

  end
end
