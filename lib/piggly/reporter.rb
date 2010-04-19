module Piggly
  class Reporter

    def self.report_path(file=nil, ext=nil)
      Piggly::Config.mkpath(Config.report_root, ext ? File.basename(file).sub(/\.[^.]+$/i, ext) : file)
    end

    def self.install(*files)
      files.each do |file|
        src = File.join(File.dirname(__FILE__), 'reporter', file)
        dst = report_path(file)

        File.open(dst, 'w') {|f| f.write File.read(src) }
      end
    end

  end
end

require File.join(File.dirname(__FILE__), *%w[reporter html])
