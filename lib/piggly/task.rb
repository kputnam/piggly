require "rake"
require "rake/tasklib"

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), ".."))
require "piggly"

module Piggly

  class AbstractTask < Rake::TaskLib
    attr_accessor :name,          # Name of the test task
                  :verbose,
                  :ruby_opts

    attr_accessor :procedures,    # List of procedure names or regular expressions, match all by default
                  :cache_root,    # Where to store cache data
                  :piggly_opts,
                  :piggly_path    # Path to bin/piggly

    def initialize(name = :piggly)
      @name        = name
      @verbose     = false
      @ruby_opts   = []

      @procedures  = []
      @cache_root  = nil
      @piggly_path = File.expand_path("#{File.dirname(__FILE__)}/../../bin/piggly")
      @piggly_opts = []

      yield self if block_given?
      define
    end

  private

    def quote(value)
      case value
      when Regexp
        quote(value.inspect)
      else
        %{"#{value}"}
      end
    end

  end

  class TraceTask < AbstractTask
    def initialize(name = :trace)
      super(name)
    end

  private

    def define
      desc 'Trace stored procedures'
      task @name do
        RakeFileUtils.verbose(@verbose) do
          opts  = []
          opts << "trace"
          opts.concat(["--cache-root", @cache_root]) if @cache_root

          case @procedures
          when String then opts.concat(["--name", @procedures])
          when Regexp then opts.concat(["--name", @procedures.inspect])
          when Array
            @procedures.each do |p|
              case p
              when String then opts.concat(["--name", p])
              when Regexp then opts.concat(["--name", p.inspect])
              end
            end
          end

          opts.concat(@piggly_opts)
        # ruby(opts.join(" "))
          Command.main(opts)
        end
      end
    end
  end

  class UntraceTask < AbstractTask
    def initialize(name = :untrace)
      super(name)
    end

  private

    def define
      desc 'Untrace stored procedures'
      task @name do
        RakeFileUtils.verbose(@verbose) do
        # opts  = @ruby_opts.clone
        # opts << (@piggly_path ? quote(@piggly_path) : "-S piggly")
          opts  = []
          opts << "untrace"
          opts.concat(["--cache-root", @cache_root]) if @cache_root

          case @procedures
          when String then opts.concat(["--name", @procedures])
          when Regexp then opts.concat(["--name", @procedures.inspect])
          when Array
            @procedures.each do |p|
              case p
              when String then opts.concat(["--name", p])
              when Regexp then opts.concat(["--name", p.inspect])
              end
            end
          end

          opts.concat(@piggly_opts)
        # ruby(opts.join(" "))
          Command.main(opts)
        end
      end
    end
  end

  class ReportTask < AbstractTask
    attr_accessor :report_root,   # Where to store reports (default piggly/report)
                  :aggregate,     # Accumulate coverage from the previous run (default false)
                  :trace_file

    def initialize(name = :report)
      @aggregate   = false
      @trace_file  = nil
      @report_root = nil
      super(name)
    end

  private

    def define
      desc 'Generate piggly report'
      task @name do
        RakeFileUtils.verbose(@verbose) do
        # opts  = @ruby_opts.clone
        # opts << (@piggly_path ? quote(@piggly_path) : "-S piggly")
          opts  = []
          opts << "report"
          opts << "--aggregate" if @aggregate
          opts.concat(["--trace-file",  @trace_file])
          opts.concat(["--cache-root",  @cache_root]) if @cache_root
          opts.concat(["--report-root", @report_root]) if @report_root

          case @procedures
          when String then opts.concat(["--name", @procedures])
          when Regexp then opts.concat(["--name", @procedures.inspect])
          when Array
            @procedures.each do |p|
              case p
              when String then opts.concat(["--name", p])
              when Regexp then opts.concat(["--name", p.inspect])
              end
            end
          end

          opts.concat(@piggly_opts)
        # ruby(opts.join(" "))
          Command.main(opts)
        end
      end
    end
  end

  class TestTask < AbstractTask
    attr_accessor :test_files,    # List of ruby test files to load
                  :report_root,   # Where to store reports (default piggly/report)
                  :aggregate      # Accumulate coverage from the previous run (default false)

    def initialize(name = :piggly)
      @report_root = nil
      @test_files  = []
      @aggregate   = false
      super(name)
    end

  private

    def define
      desc 'Run piggly tests' + (@name == :piggly ? '' : " for #{@name}")
      task @name do
        RakeFileUtils.verbose(@verbose) do
          opts  = @ruby_opts.clone
          opts << (@piggly_path ? quote(@piggly_path) : "-S piggly")
          opts << "test"
          opts << "--aggregate" if @aggregate
          opts << "--cache-root #{quote @cache_root}" if @cache_root
          opts << "--report-root #{quote @report_root}" if @report_root

          case @procedures
          when String then opts << "--name #{quote @procedures}"
          when Regexp then opts << "--name #{quote @procedures.inspect}"
          when Array
            @procedures.each do |p|
              case p
              when String then opts << "--name #{quote p}"
              when Regexp then opts << "--name #{quote p.inspect}"
              end
            end
          end

          opts.concat(@piggly_opts)

          unless (@test_files || []).empty?
            opts << "--"
            opts.concat(@test_files.map{|x| quote(x) })
          end

          ruby(opts.join(" "))
        end
      end
    end
  end

end
