require 'rake'
require 'rake/tasklib'
require 'piggly'

module Piggly
  class Task < Rake::TaskLib
    attr_accessor :name,          # Name of the test task
                  :libs,          # List of paths added to $LOAD_PATH before running tests
                  :test_files,    # List of ruby test files to load
                  :verbose,
                  :warning,       # Execute ruby -w if true
                  :report_root,   # Where to store reports (default piggly/report)
                  :cache_root,    # Where to store compiler cache (default piggly/cache)
                  :cache_key,     # Stored procedure's attribute to use as a cache key
                  :aggregate,     # Accumulate coverage from the previous run (default false)
                  :procedures,    # List of procedure names or regular expressions, match all by default
                  :piggly_opts,
                  :piggly_path    # Path to bin/piggly (default searches with ruby -S)

    def initialize(name = :piggly)
      @name = name
      @libs = %w[]
      @verbose     = false
      @warning     = false
      @test_files  = []
      @ruby_opts   = []
      @report_root = Piggly::Config.report_root
      @cache_root  = Piggly::Config.cache_root
      @cache_key   = Piggly::Config.identify_procedures_using
      @procedures  = []
      @piggly_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'piggly'))
      @piggly_opts = ''
      @aggregate   = false
      yield self if block_given?
      define
    end

    # create tasks defined by this task lib
    def define
      desc 'Run piggly tests' + (@name == :piggly ? '' : " for #{@name}")
      task @name do
        @piggly_opts << "--aggregate" if @aggregate

        RakeFileUtils.verbose(@verbose) do
          run_code  = (piggly_path.nil?) ? '-S piggly' : quote(piggly_path)
          opts = @ruby_opts.clone
          opts.push "-I#{Array(@libs).join(File::PATH_SEPARATOR)}"
          opts.push '-w' if @warning
          opts.push run_code
          opts.push 'test'

          ruby opts.join(' ') + ' ' +
               @piggly_opts   + ' ' +
               %{-o #{quote @report_root} } +
               %{-c #{quote @cache_root} } +
               %{-k #{quote @cache_key} } +
               procedures.map{|x| '-n ' + quote(x) }.join(' ') + ' ' +
               test_files.map{|x|         quote(x) }.join(' ')
        end

      end
    end

    def quote(value)
      case value
      when Regexp
        quote(value.inspect)
      else
        %{"#{value}"}
      end
    end

  end
end
