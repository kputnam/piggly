module Piggly
  class Config

    def self.instance
      @instance ||= new
    end

    def self.method_missing(name, *args, &block)
      if instance.respond_to?(name)
        instance.send(name, *args, &block)
      else
        super
      end
    end

    def self.respond_to?(name)
      super or instance.respond_to?(name)
    end

    def self.config_accessor(hash)
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

    def path(root, file=nil)
      if file
        file[%r{^\.\.|^\/|^(?:[A-Z]:)?/}i] ?
          file : # ../path, /path, or D:\path that isn't relative to root
          File.join(root, file)
      else
        root
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

    config_accessor :cache_root   => File.expand_path(File.join(Dir.pwd, 'piggly', 'cache')),
                    :report_root  => File.expand_path(File.join(Dir.pwd, 'piggly', 'reports')),
                    :trace_prefix => 'PIGGLY',
                    :aggregate    => false,
                    :identify_procedures_using => 'signature'
  end
end
