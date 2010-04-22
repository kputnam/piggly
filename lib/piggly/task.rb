require 'rake'
require 'rake/tasklib'

module Piggly
  class Task < Rake::TaskLib
    attr_accessor :name,          # Name of the test task
                  :libs,          # List of paths added to $LOAD_PATH before running tests
                  :test_files,    # List of ruby test files to load
                  :proc_files,    # List of pl/pgsql stored procedures to compile
                  :verbose,
                  :warning,       # Execute ruby -w if true
                  :report_dir,    # Where to store reports (default piggly/report)
                  :cache_root,    # Where to store compiler cache (default piggly/cache)
                  :aggregate,     # Accumulate coverage from the previous run (default false)
                  :piggly_opts,
                  :piggly_path    # Path to bin/piggly (default searches with ruby -S)

    def initialize(name = :piggly)
      @name = name
      @libs = %w[]
      @verbose    = false
      @warning    = false
      @test_files = []
      @proc_files = []
      @ruby_opts  = []
      @report_dir = 'piggly/report'
      @cache_root = 'piggly/cache'
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
          opts.push run_code
          opts.push '-w' if @warning

          ruby opts.join(' ') + ' ' +
               @piggly_opts   + ' ' +
               %{-o #{quote @report_dir} } +
               %{-c #{quote @cache_root} } +
               proc_files.map{|s| %[-s "#{s}" ] }.join +
               test_files.map{|f| quote(f) }.join(' ')
        end

      end
    end

    def quote(string)
      %{"#{string}"}
    end

  end
end
