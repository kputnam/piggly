module Piggly
  module CompilerCache
    def self.included(subclass)
      subclass.extend(ClassMethods)
    end

    #
    # Each cache unit (any group of data that should be expired and created
    # together) can be broken apart, to prevent unmarshaling a huge block of
    # data all at once.
    #
    # The interface works like a Hash, so the compile method should return a
    # hash of objects. Each object is writen to a different file (named by the
    # hash key) within the same directory. String objects are (usually) read
    # and written directly to disk, while all other objects are (un-)Marshal'd
    #
    # Cache invalidation is done by comparing last-modified timestamps on the
    # cached object's file to all the "source" files (ruby libs, input files,
    # etc) required to regenerate the data.
    #
    class FileCache
      HINT = /[\000-\010\016-\037\177-\300]/

      class << self
        def lookup(cachedir, data={})
          store[cachedir] ||= new(cachedir, data)
        end

        def dump(cachedir, hash)
          FileUtils.mkdir(cachedir) unless File.exists?(cachedir)
          FileUtils.touch(cachedir)

          for key, data in hash
            File.open(File.join(cachedir, key.to_s), 'wb') do |f|
              if data.is_a?(String) and data[0,2] !~ HINT
                # even Strings will be Marshal'd if the first two bytes contain non-ASCII
                f.write data
              else
                Marshal.dump(data, f)
              end
            end
          end

          return hash
        end

        def load(cachedir, key)
          File.open(File.join(cachedir, key.to_s)) do |io|
            # detect Marshal'd data
            if io.read(2) !~ HINT
              io.rewind
              io.read
            else
              io.rewind
              Marshal.load(io)
            end
          end
        end

        # Creates cachedir (if missing) and destroys its contents
        def clean(cachedir)
          FileUtils.mkdir(cachedir) unless File.exists?(cachedir)
          FileUtils.touch(cachedir)
          FileUtils.rm(Dir["#{cachedir}/*"])
        end

        def store
          @store ||= {}
        end
      end

      # Destroys any existing cached data and write the given data to disk if data is not empty
      def initialize(cachedir, data={})
        @dir  = cachedir
        @data = {}
        replace(data) unless data.empty?
      end

      def [](key)
        @data[key.to_s] ||= self.class.load(@dir, key)
      end

      # Writes through to file system
      def []=(key, value)
        @data[key.to_s] = value
        self.class.dump(@dir, key.to_s => value)
      end

      # Writes through to file system
      def update(hash)
        hash.each do |key,value|
          self[key] = value
        end
      end

      def keys
        Dir[@dir + '/*'].map{|e| File.basename(e) } | @data.keys
      end

      private

      # Clears entire cache and replaces contents
      def replace(data)
        self.class.clean(@dir)
        self.class.dump(@dir, data)

        for key, value in data
          # stringify keys
          @data[key.to_s] = data
        end
      end
    end

    #
    # Base class should define self.compiler_path and self.compile(tree, ...)
    #
    module ClassMethods
      def cache_sources
        [compiler_path, Parser.grammar_path, Parser.parser_path, Parser.nodes_path]
      end

      def stale?(source)
        File.stale?(cache_path(source), source, *cache_sources)
      end

      # returns FileCache instance 
      def cache(source, args={}, &block)
        Parser.parser # load libraries
        cachedir = cache_path(source)

        if stale?(source)
          begin
            tree = Parser.cache(source)
            data = compile(tree, args.update(:path => source), &block)
            
            # replaces old cached data with new data
            FileCache.lookup(cachedir, data)
          rescue Piggly::Parser::Failure
            FileCache.clean(cachedir)
            raise
          end
        else
          FileCache.lookup(cachedir)
        end
      end
    end

  end
end
