module Piggly
  module Command

    #
    # This command reads a given file (or STDIN) which is expected to contain messages like the
    # pattern Profile::PATTERN, which is probbaly "WARNING:  PIGGLY 0123456789abcdef".
    #
    # Lines in the input that match this pattern are profiled and used to generate a report
    #
    class Report < Base
    end

    class << Report
      def main(argv)
        require "pp"
        io, config = configure(argv)

        profile = Profile.new
        index   = Dumper::Index.new(config)

        procedures = filter(config, index)

        if procedures.empty?
          if filters.empty?
            abort "no stored procedures in the cache"
          else
            abort "no stored procedures in the cache matched your criteria"
          end
        end

        profile_procedures(config, procedures, profile)
        clear_coverage(config, profile)

        read_profile(config, io, profile)
        store_coverage(profile)

        create_index(config, index, procedures, profile)
        create_reports(config, procedures, profile)
      end

      # Adds the given procedures to Profile
      #
      def profile_procedures(config, procedures, profile)
        # register each procedure in the Profile
        compiler = Compiler::TraceCompiler.new(config)
        procedures.each do |p|
          result = compiler.compile(p)
          profile.add(p, result[:tags], result)
        end
      end

      # Clear coverage after procedures have been loaded
      #
      def clear_coverage(config, profile)
        unless config.accumulate?
          puts "clearing previous coverage"
          profile.clear
        end
      end

      # Reads +io+ for lines matching Profile::PATTERN and records coverage
      #
      def read_profile(config, io, profile)
        np = profile.notice_processor(config)
        io.each{|line| np.call(line) }
      end

      # Store the coverage Profile on disk
      #
      def store_coverage(profile)
        puts "storing coverage profile"
        profile.store
      end

      # Create the report's index.html
      #
      def create_index(config, index, procedures, profile)
        puts "creating index"
        reporter = Reporter::Index.new(config, profile)
        reporter.install("resources/piggly.css", "resources/sortable.js")
        reporter.report(procedures, index)
      end

      # Create each procedures' HTML report page
      #
      def create_reports(config, procedures, profile)
        puts "creating reports"
        queue = Util::ProcessQueue.new

        compiler = Compiler::TraceCompiler.new(config)
        reporter = Reporter::Procedure.new(config, profile)

        Parser.parser

        procedures.each do |p|
          queue.add do
            unless compiler.stale?(p)
              data = compiler.compile(p)
              path = reporter.report_path(p.source_path(config), ".html")

              unless profile.empty?(data[:tags])
                changes = ": #{profile.difference(p, data[:tags])}"
              end

              puts "reporting coverage for #{p.name}#{changes}"
            # pp data[:tags]
            # pp profile[p]
            # puts

              reporter.report(p)
            end
          end
        end

        queue.execute
      end

      def configure(argv, config = Config.new)
        io = $stdin
        p  = OptionParser.new do |o|
          o.on("-c", "--cache-root PATH",   "local cache directory", &o_cache_root(config))
          o.on("-n", "--name PATTERN",      "trace stored procedures matching PATTERN", &o_filter(config))
          o.on("-o", "--report-root PATH",  "report output directory", &o_report_root(config))
          o.on("-a", "--accumulate",        "accumulate data from the previous run", &o_accumulate(config))
          o.on("-V", "--version",           "show version", &o_version(config))
          o.on("-h", "--help",              "show this message") { abort o.to_s }
          o.on("-f", "--input PATH",        "read trace messages from PATH") do |path|
            io = if path == "-"
                   $stdin
                 else
                   File.open(path, "rb")
                 end
          end
        end

        begin
          p.parse! argv
          
          if io.eql?($stdin) and $stdin.tty?
            raise OptionParser::MissingArgument,
              "stdin must be a pipe, or use --input PATH"
          end

          return io, config
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
