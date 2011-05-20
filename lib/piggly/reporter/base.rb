module Piggly
  module Reporter

    class Base

      # Copy each file to @config.report_root
      def install(*files)
        files.each do |name|
          src = File.join(File.dirname(__FILE__), "reporter", name)
          dst = report_path(name)

          File.open(dst, "w"){|io| io.write(File.read(src)) }
        end
      end

      def report_path(file=nil, ext=nil)
        unless file.nil?
          # Remove the original extension from +file+ and add given extension
          @config.mkpath(@config.report_root, ext ?
            File.basename(file, ".*") + ext :
            File.basename(file))
        else
          @config.mkpath(@config.report_root)
        end
      end
    end

  end
end
