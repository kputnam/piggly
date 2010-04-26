module Piggly
  class Reporter
    class << self
      # Copy each file to Config.report_root
      def install(*files)
        files.each do |file|
          src = File.join(File.dirname(__FILE__), 'reporter', file)
          dst = report_path(file)

          File.open(dst, 'w') {|f| f.write File.read(src) }
        end
      end

      def report_path(file=nil, ext=nil)
        Piggly::Config.mkpath(Config.report_root, ext ? File.basename(file).sub(/\.[^.]+$/i, ext) : file)
      end
    end

  end
end

require File.join(File.dirname(__FILE__), *%w[reporter html html_dsl])
require File.join(File.dirname(__FILE__), *%w[reporter html])
require File.join(File.dirname(__FILE__), *%w[reporter html index])
