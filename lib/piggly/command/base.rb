module Piggly
  module Command

    class Base
    end

    class << Base

      def main(argv)
        cmd, argv = command(argv)

        if cmd.nil?
          abort "usage: #{$0} {test|report|trace|untrace} --help"
        else
          cmd.main(argv)
        end
      end

    private

      # @return [(Class, Array<String>)]
      def command(argv)
        return if argv.empty?
        head, *tail = argv

        case head.downcase
        when "report";  [Report,  tail]
        when "test";    [Test,    tail]
        when "trace";   [Trace,   tail]
        when "untrace"; [Untrace, tail]
        end
      end

      # @return [PGconn]
      def connect(config)
        require "pg"
        require "erb"

        files = Array(config.database_yml ||
          %w(piggly/database.yml
             config/database.yml
             piggly/database.json
             config/database.json))

        path = files.find{|x| File.exists?(x) } or
          raise "No database config files found: #{files.join(", ")}"

        specs =
          if File.extname(path) == ".json"
            require "json"
            JSON.load(ERB.new(IO.read(path)).result)
          else
            require "yaml"
            YAML.load(ERB.new(IO.read(path)).result)
          end

        spec = (specs.is_a?(Hash) and specs[config.connection_name]) or
          raise "Database '#{config.connection_name}' is not configured in #{path}"

        PGconn.connect(spec["host"], spec["port"], nil, nil,
          spec["database"], spec["username"], spec["password"])
      end

      # @return [Enumerable<SkeletonProcedure>]
      def filter(config, index)
        if config.filters.empty?
          index.procedures
        else
          config.filters.inject(Set.new){|s, f| s | index.procedures.select(&f) }
        end
      end

      def o_accumulate(config)
        lambda{|x| config.accumulate = x }
      end

      def o_cache_root(config)
        lambda{|x| config.cache_root = x }
      end

      def o_report_root(config)
        lambda{|x| config.report_root = x }
      end

      def o_include_paths(config)
        lambda{|x| config.include_paths.concat(x.split(":")) }
      end

      def o_database_yml(config)
        lambda{|x| config.database_yml = x }
      end

      def o_connection_name(config)
        lambda{|x| config.connection_name = x }
      end

      def o_version(config)
        lambda { puts "piggly #{VERSION} #{VERSION::RELEASE_DATE}"; exit! }
      end

      def o_filter(config)
        lambda do |x|
          if m = x.match(%r{^/([^/]+)/$})
            config.filters << lambda{|p| p.name.match(m.captures.first) }
          else
            config.filters << lambda{|p| p.name === x }
          end
        end
      end
    end

  end
end
