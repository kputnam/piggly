module Piggly
  class Config
  end

  class << Config
    def path(root, file=nil)
      if file.nil?
        root
      else
        file[%r{^\.\.|^\/|^(?:[A-Z]:)?/}i] ?
          file : # ../path, /path, or D:\path that isn't relative to root
          File.join(root, file)
      end
    end

    def mkpath(root, file=nil)
      if file.nil?
        FileUtils.makedirs(root)
        root
      else
        path = path(root, file)
        FileUtils.makedirs(File.dirname(path))
        path
      end
    end

    def config_accessor(hash)
      hash = hash.clone

      hash.keys.each do |name|
        define_method(name) do
          instance_variable_get("@#{name}") || hash[name]
        end

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
        end
      end
    end

  end

  class Config
    config_accessor \
      :cache_root   => File.expand_path("#{Dir.pwd}/piggly/cache"),
      :report_root  => File.expand_path("#{Dir.pwd}/piggly/reports"),
      :trace_prefix => "PIGGLY",
      :aggregate    => false

    alias aggregate? aggregate
  end
end
