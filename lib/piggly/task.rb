require 'rake'
require 'rake/tasklib'

module Piggly
  class Task < Rake::TaskLib
    attr_accessor :name,          # name of the test task
                  :libs,          # list of paths added to $LOAD_PATH before running tests
                  :test_files,    # list of ruby test files to load
                  :proc_files,    # list of pl/pgsql stored procedures to compile
                  :verbose,
                  :warning,       # execute ruby -w if true
                  :report_dir,    # where to store reports (default piggly/report)
                  :cache_root,    # where to store compiler cache (default piggly/cache)
                  :aggregate,     # accumulate coverage from the previous run (default false)
                  :piggly_opts,
                  :piggly_path    # path to bin/piggly (default searches with ruby -S)

    def initialize(name = :piggly)
      @name = name
      @libs = %w[]
      @verbose    = false
      @warning    = false
      @test_files = []
      @proc_files = []
      @ruby_opts  = []
      @output_dir = 'piggly/output'
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
               %{-o #{quote @output_dir} } +
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
