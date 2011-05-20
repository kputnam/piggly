module Piggly
  module Command

    #
    # This command connects to the database, dumps all stored procedures, compiles them
    # with instrumentation code, and finally installs the instrumented code.
    #
    class Trace < Base
    end

    class << Trace
      def main(argv)
        config     = configure(argv)
        connection = connect(config)
        index      = Dumper::Index.new(config)

        dump(connection, index)

        procedures = filter(config, index)

        if procedures.empty?
          if filters.empty?
            abort "no stored procedures in the cache"
          else
            abort "no stored procedures in the cache matched your criteria"
          end
        end

        trace(config, procedures)
        install(Installer.new(config, connection), procedures, Profile.new)
      end

      # Writes all stored procedures in the database to disk
      #   @return [void]
      def dump(connection, index)
        index.update(Dumper::ReifiedProcedure.all(connection))
      end

      # Compiles all the stored procedures on disk and installs them
      #   @return [void]
      def trace(config, procedures)
        puts "compiling #{procedures.size} procedures"

        compiler = Compiler::TraceCompiler.new(config)
        queue    = Util::ProcessQueue.new
        procedures.each{|p| queue.add { compiler.compile(p) }}

        # Force parser to load before we start forking
        Parser.parser
        queue.execute
      end

      def install(installer, procedures, profile)
        puts "tracing #{procedures.size} procedures"
        installer.install(procedures, profile)
      end

      # Parses command-line options
      #   @return [Config]
      def configure(argv, config = Config.new)
        p = OptionParser.new do |o|
          o.on("-c", "--cache-root PATH", "local cache directory", &o_cache_root(config))
          o.on("-d", "--database PATH",   "read 'piggly' database adapter settings from YAML file", &o_database_yml(config))
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
