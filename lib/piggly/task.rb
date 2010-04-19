require 'rake'
require 'rake/tasklib'

module Piggly
  class Task < Rake::TaskLib
    attr_accessor :name,
                  :libs,
                  :test_files,
                  :verbose,
                  :warning,
                  :output_dir,
                  :cache_root,
                  :source_root,
                  :aggregate,
                  :piggly_opts,
                  :piggly_path

    def initialize(name = :piggly)
      @name = name
      @libs = %w[]
      @verbose    = false
      @warning    = false
      @test_files = []
      @ruby_opts  = []
      @output_dir = 'piggly/output'
      @cache_root = 'piggly/cache'
      @source_root = 'piggly/sql'
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
        @libs = Array(@libs)

        if @aggregate
          @piggly_opts << "--aggregate"
        end

        RakeFileUtils.verbose(@verbose) do
          run_code  = (piggly_path.nil?) ? '-S piggly' : quote(piggly_path)
          opts = @ruby_opts.clone
          opts.push "-I#{@libs.join(File::PATH_SEPARATOR)}"
          opts.push run_code
          opts.push '-w' if @warning

          ruby opts.join(' ') + ' ' +
               @piggly_opts   + ' ' +
               %{-o #{quote @output_dir} } +
               %{-c #{quote @cache_root} } +
               @source_root.map{|s| %{-s "#{s}" } }.join +
               test_files.map{|f| quote(f) }.join(' ')
        end

      end
    end

    def quote(string)
      %{"#{string}"}
    end

  end
end
