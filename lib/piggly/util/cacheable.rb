module Piggly
  module Util
    module Cacheable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def cache_path(file, config)
          # Up to the last capitalized word of the class name
          classdir = name[/^(?:.+::)?(.+?)([A-Z][^A-Z]+)?$/, 1]

          # md5 the full path to prevent collisions
          full = ::File.expand_path(file)
          hash = Digest::MD5.hexdigest(::File.dirname(full))
          base = ::File.basename(file)

          config.mkpath(::File.join(config.cache_root, classdir), base)
        end
      end

    end
  end
end
