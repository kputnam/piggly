module Piggly
  module Command

    autoload :Report,   'piggly/command/report'
    autoload :Test,     'piggly/command/test'
    autoload :Trace,    'piggly/command/trace'
    autoload :Untrace,  'piggly/command/untrace'

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

        case argv.first.downcase
        when 'report'
          [Report, argv[1 .. -1]]
        when 'test'
          [Test, argv[1 .. -1]]
        when 'trace'
          [Trace, argv[1 .. -1]]
        when 'untrace'
          [Untrace, argv[1 .. -1]]
        end
      end

      def connect_to_database
        Command.load_activerecord
        ActiveRecord::Base.connection.active?
      rescue
        begin
          Command.opt_database('database.yml')
        rescue
          ActiveRecord::Base.establish_connection
        end
      end

      def opt_database(path)
        load_activerecord

        begin
          require 'erb'
          ActiveRecord::Base.configurations = YAML.load(ERB.new(IO.read(path)).result)
        rescue LoadError
          ActiveRecord::Base.configurations = YAML.load(IO.read(path))
        end
        
        ActiveRecord::Base.establish_connection 'piggly'
        ActiveRecord::Base.connection.active?
      end

      def opt_cache_root(dir)
        Piggly::Config.cache_root = dir
      end

      def opt_cache_key(mode)
        Piggly::Config.identify_procedures_using = mode
      end

      def opt_report_root(dir)
        Piggly::Config.report_root = dir
      end

      def opt_include_path(paths)
        $:.concat(paths.split(':'))
      end

      def opt_aggregate(switch)
        Piggly::Config.aggregate = switch
      end

      def opt_version(*args)
        puts "piggly #{Piggly::VERSION::STRING} #{Piggly::VERSION::RELEASE_DATE}"
        exit!
      end

      def load_activerecord
        require 'active_record'
        require 'pg'
      end
    end

  end
end
