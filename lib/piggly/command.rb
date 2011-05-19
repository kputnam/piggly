module Piggly
  module Command

    autoload :Report,   "piggly/command/report"
    autoload :Test,     "piggly/command/test"
    autoload :Trace,    "piggly/command/trace"
    autoload :Untrace,  "piggly/command/untrace"

    class << self
      def main(argv)
        command, argv = parse_options(argv)

        if command
          command.main(argv)
        else
          abort "Usage: #{$0} {test|report|trace|untrace} --help"
        end
      end

      # returns subcommand and remaining arguments
      def parse_options(argv)
        return if argv.empty?

        first, *rest = argv
        case first.downcase
        when "report"
          [Report, rest]
        when "test"
          [Test, rest]
        when "trace"
          [Trace, rest]
        when "untrace"
          [Untrace, rest]
        end
      end

      def opt_cache_root(dir)
        Config.cache_root = dir
      end

      def opt_cache_key(mode)
        Config.identify_procedures_using = mode
      end

      def opt_report_root(dir)
        Config.report_root = dir
      end

      def opt_include_path(paths)
        $:.concat paths.split(":")
      end

      def opt_aggregate(switch)
        Config.aggregate = switch
      end

      def opt_version(*args)
        puts "piggly #{Piggly::VERSION::STRING} #{Piggly::VERSION::RELEASE_DATE}"
        exit!
      end

      def connect_to_database
        load_activerecord

        ActiveRecord::Base.connection.active?
      rescue
        if File.exists?("piggly/database.yml")
          Command.opt_database("piggly/database.yml")
        elsif File.exists?("config/database.yml")
          Command.opt_database("config/database.yml")
        else
          raise
        # ActiveRecord::Base.establish_connection
        end
      end

      def opt_database(path)
        load_activerecord

        begin
          require "erb"
          ActiveRecord::Base.configurations = YAML.load(ERB.new(IO.read(path)).result)
        rescue LoadError
          ActiveRecord::Base.configurations = YAML.load(IO.read(path))
        end
        
        ActiveRecord::Base.establish_connection "piggly"
        ActiveRecord::Base.connection.active?
      end

      def load_activerecord
        require "active_record"
        require "pg"
      end
    end

  end
end
