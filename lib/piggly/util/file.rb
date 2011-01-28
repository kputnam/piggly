module Piggly
  module Util
    module File

      # True if target file is older (by mtime) than any source file
      def self.stale?(target, *sources)
        if ::File.exists?(target)
          oldest = ::File.mtime(target)
          sources.any?{|x| ::File.mtime(x) > oldest }
        else
          true
        end
      end

    end
  end
end
