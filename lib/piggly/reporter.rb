module Piggly
  module Reporter

    autoload :Html, "piggly/reporter/html"

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Copy each file to Config.report_root
      def install(config, *files)
        files.each do |name|
          src = File.join(File.dirname(__FILE__), "reporter", name)
          dst = report_path(config, name)

          File.open(dst, "w"){|io| io.write(File.read(src)) }
        end
      end

      def report_path(config, file=nil, ext=nil)
        unless file.nil?
          # Remove the original extension from +file+ and add given extension
          config.mkpath(config.report_root, ext ?
                          File.basename(file, ".*") + ext :
                          File.basename(file))
        else
          config.mkpath(config.report_root)
        end
      end
    end

    extend ClassMethods

    class AbstractReporter
      include Reporter
    end
  end
end
