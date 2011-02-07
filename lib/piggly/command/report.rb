module Piggly
  module Command

    #
    # This command reads a given file (or STDIN) which is expected to contain messages like the
    # pattern Piggly::Profile::PATTERN, which is probbaly "WARNING:  PIGGLY 0011223344556677".
    #
    # Lines in the input that match this pattern are profiled and used to generate a report
    #
    module Report
      class << self

        def main(argv)
          io, filters = parse_options(argv)

          procedures = find_procedures(filters)

          if procedures.empty?
            abort "No stored procedures in the cache#{' matched your criteria' if filters.any?}"
          end

          profile_procedures(procedures)
          clear_coverage

          read_profile(io)
          store_coverage

          create_index(procedures)
          create_reports(procedures)
        end

        #
        # Returns a list of Procedure values that satisfy at least one of the given filters
        #
        def find_procedures(filters)
          index = Piggly::Dumper::Index.instance

          if filters.empty?
            index.procedures
          else
            filters.inject(Set.new){|set, filter| set | index.procedures.select(&filter) }
          end
        end

        # 
        # Adds the given procedures to Profile
        #
        def profile_procedures(procedures)
          profile = Piggly::Profile.instance

          # register each procedure in the Profile
          procedures.each do |procedure|
            result = Piggly::Compiler::Trace.cache(procedure, procedure.oid)
            profile.add(procedure, result[:tags], result)
          end
        end

        #
        # Clear coverage after procedures have been loaded
        #
        def clear_coverage
          unless Piggly::Config.aggregate
            puts "Clearing previous coverage"
            Piggly::Profile.instance.clear
          end
        end

        #
        # Reads +io+ for lines matching Piggly::Profile::PATTERN and records coverage
        #
        def read_profile(io)
          profile = Piggly::Profile.instance

          io.each do |line|
            if m = Piggly::Profile::PATTERN.match(line)
              profile.ping(m.captures[0], m.captures[1])
            end
          end
        end

        #
        # Store the coverage Profile on disk
        #
        def store_coverage
          puts "Storing coverage profile"
          Piggly::Profile.instance.store
        end

        #
        # Create the report's index.html
        #
        def create_index(procedures)
          puts "Creating index"
          Piggly::Reporter.install('html/piggly.css', 'html/sortable.js')
          Piggly::Reporter::Html::Index.output(procedures)
        end

        #
        # Create each procedures' HTML report page
        #
        def create_reports(procedures)
          puts "Creating reports"

          profile = Piggly::Profile.instance
          queue   = Piggly::Util::ProcessQueue.new

          procedures.each do |p|
            queue.add do
              path = Piggly::Reporter.report_path(p.source_path, '.html')
              data = Piggly::Compiler::Trace.cache(p, p.oid)
              live = Piggly::Profile.instance[p] rescue nil

              if File.exists?(p.source_path)
                needed   = Piggly::Util::File.stale?(path, p.source_path)
                needed ||= data[:tags] != live
              else
                needed = false
              end

              if needed
                unless profile.empty?(data[:tags])
                  changes = ": #{profile.difference(p, data[:tags])}"
                end

                puts "Reporting coverage for #{p.name}#{changes}"
                result = Piggly::Compiler::Report.compile(p, profile)
                Piggly::Reporter::Html.output(p, result[:html], result[:lines])
              end
            end
          end

          queue.execute
        end

        def parse_options(argv)
          filters = []
          io      = nil

          opts = OptionParser.new do |opts|
            opts.on("-f", "--trace-file PATH", "Read trace messages from PATH") do |path|
              io = if path == '-'
                     $stdin
                   else
                     File.open(path, "rb")
                   end
            end

            opts.on("-c", "--cache-root PATH", "Local cache directory", &Command.method(:opt_cache_root))
            opts.on("-o", "--report-root PATH", "Report output directory", &Command.method(:opt_report_root))
            opts.on("-a", "--aggregate", "Aggregate data from the previous run", &Command.method(:opt_aggregate))

            opts.on("-n", "--name PATTERN", "Trace stored procedures matching PATTERN") do |opt|
              if m = opt.match(%r{^/(.+)/$})
                filters << lambda{|p| p.name.match(m.captures.first) }
              else
                filters << lambda{|p| p.name === opt }
              end
            end

            opts.on("-V", "--version", "Show version", &Command.method(:opt_version))
            opts.on("-h", "--help", "Show this message") do
              puts opts
              exit!
            end
          end

          begin
            opts.parse! argv
            if io.nil? and $stdin.tty?
              raise OptionParser::MissingArgument, "must pipe STDIN or use --trace-file"
            end
          rescue OptionParser::InvalidOption,
                 OptionParser::InvalidArgument,
                 OptionParser::MissingArgument
            puts opts
            puts
            puts $!

            exit! 1
          end

          if io.nil?
            io = $stdin
          end

          return io, filters
        end

      end
    end

  end
end
