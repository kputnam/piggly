class File
  def self.stale?(target, *sources)
    if exists?(target)
      oldest = mtime(target)
      sources.find{|x| mtime(x) > oldest }
    else
      true
    end
  end
end

module Piggly
  module FileCache
    def self.included(subclass)
      subclass.extend(ClassMethods)
    end

    module ClassMethods
      # map source path to cache file path
      def cache_path(file)
        # up to the last capitalized word of the class name
        subdir = name[/^(?:.+::)?(.+?)([A-Z][^A-Z]+)?$/, 1]
        root   = File.join(Config.cache_root, subdir)

        # md5 the full path to prevent collisions
        full = File.expand_path(file)
        base = File.basename(full)
        hash = Digest::MD5.hexdigest(File.dirname(full))

        Config.mkpath(File.join(Config.cache_root, hash, subdir), base)
      end
    end

  end
end
