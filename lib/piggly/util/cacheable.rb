module Piggly
  module Util
    module Cacheable

      def cache_path(file)
        # Up to the last capitalized word of the class name
        classdir = self.class.name[/^(?:.+::)?(.+?)([A-Z][^A-Z]+)?$/, 1]

        # md5 the full path to prevent collisions
        full = ::File.expand_path(file)
        hash = Digest::MD5.hexdigest(::File.dirname(full))
        base = ::File.basename(file)

        @config.mkpath(::File.join(@config.cache_root, classdir), base)
      end

    end
  end
end
