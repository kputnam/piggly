module Piggly
  module Compiler
    module Cacheable

      def self.included(subclass)
        subclass.extend(ClassMethods)
        subclass.send(:include, Piggly::Util::Cacheable)
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
      # Cache invalidation is done by comparing mtime timestamps on the cached
      # object's file to all the "source" files (ruby libs, input files, etc)
      # required to regenerate the data.
      #
      class CacheDirectory
        # Non-printable ASCII char indicates data should be Marshal'd
        HINT = /[\000-\010\016-\037\177-\300]/

        def self.lookup(cachedir)
          new(cachedir)
        end

        def initialize(cachedir)
          @dir  = cachedir
          @data = {}
        end

        # Load given key from file system into memory if needed
        def [](key)
          unless @data.include?(key.to_s)
            @data[key.to_s] =
              File.open(File.join(@dir, key.to_s)) do |io|
                # detect Marshal'd data
                if io.read(2) !~ HINT
                  io.rewind
                  io.read
                else
                  io.rewind
                  Marshal.load(io)
                end
              end if File.exists?(File.join(@dir, key.to_s))
          end

          @data[key.to_s]
        end

        # Writes through to file system
        def []=(key, value)
          @data[key.to_s] = value
          write(key.to_s => value)
        end

        # Writes through to file system and returns self
        def update(hash)
          for key, value in hash
            self[key] = value
          end

          self
        end

        def keys
          Dir[@dir + '/*'].map{|e| File.basename(e) } | @data.keys
        end

        # Creates cachedir, destroys its contents, and returns self
        def clear
          @data.clear

          if File.exists?(@dir)
            FileUtils.rm(Dir["#{@dir}/*"])
          else
            FileUtils.mkdir(@dir) 
          end

          FileUtils.touch(@dir)

          self
        end

        # Clears entire cache, replaces contents, and returns self
        def replace(hash)
          clear
          update(hash)
        end

      private

        # Serializes each entry to disk
        def write(hash)
          FileUtils.mkdir(@dir) unless File.directory?(@dir)
          FileUtils.touch(@dir) # update mtime

          for key, data in hash
            File.open(File.join(@dir, key.to_s), 'wb') do |io|
              # Marshal if the first two bytes contain non-ASCII
              if data.is_a?(String) and data[0,2] !~ HINT
                io.write data
              else
                Marshal.dump(data, io)
              end
            end
          end
        end

      end

      #
      # Base class should define self.compile(tree, ...)
      #
      module ClassMethods

        # Each of these files' mtimes are used to determine when another file is stale
        def cache_sources
          [ Piggly::Parser.grammar_path,
            Piggly::Parser.parser_path,
            Piggly::Parser.nodes_path ]
        end

        def stale?(path)
          # is the cache_path is older than its source path or the other files?
          File.stale?(cache_path(path), path, *cache_sources)
        end

        def cache(procedure, *args, &block)
          # load parser runtime
          Piggly::Parser.parser

          cachedir = cache_path(procedure.source_path)

          if stale?(procedure.source_path)
            puts "Compiling #{procedure.name}"

            tree = Piggly::Parser.parse(File.read(procedure.source_path))
            data = compile(tree, *args, &block)
            
            cache = CacheDirectory.lookup(cachedir)
            cache.replace(data)
            cache
          else
            CacheDirectory.lookup(cachedir)
          end
        end
      end

    end
  end
end
