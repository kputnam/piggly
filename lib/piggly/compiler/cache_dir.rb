module Piggly
  module Compiler

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
    class CacheDir
      # Non-printable ASCII char indicates data should be Marshal'd
      HINT = /[\000-\010\016-\037\177-\300]/

      def initialize(dir)
        @dir  = dir
        @data = Hash.new do |h, k|
          path = File.join(@dir, k.to_s)
          if File.exists?(path)
            h[k.to_s] = File.open(path) do |io|
              # Detect Marshal'd data
              if io.read(2) !~ HINT
                io.rewind
                io.read
              else
                io.rewind
                Marshal.load(io)
              end
            end
          end
        end
      end

      # Load given key from file system into memory if needed
      #   @return [Object]
      def [](key)
        @data[key.to_s]
      end

      # Writes through to file system
      #   @return [void]
      def []=(key, value)
        @data[key.to_s] = value
        write(key.to_s => value)
      end

      # Writes through to file system and returns self
      #   @return [CacheDir] self
      def update(hash)
        hash.each{|k,v| self[k] = v }
        self
      end

      # @return [void]
      def delete(key)
        path = File.join(@dir, key.to_s)
        File.unlink(path) if File.exists?(path)
        @data.delete(key)
      end

      # @return [Array<String>]
      def keys
        Dir[@dir + "/*"].map{|f| File.basename(f) }
      end

      # Creates cachedir, destroys its contents, and returns self
      #   @return [CacheDir] self
      def clear
        @data.clear

        if File.exists?(@dir)
          FileUtils.rm(Dir["#{@dir}/*"])
          FileUtils.touch(@dir)
        else
          FileUtils.mkdir(@dir) 
        end

        self
      end

      # Clears entire cache, replaces contents, and returns self
      #   @return [CacheDir] self
      def replace(hash)
        clear
        update(hash)
      end

    private

      # Serializes each entry to disk
      #   @return [void]
      def write(hash)
        FileUtils.mkdir(@dir) unless File.exists?(@dir)
        FileUtils.touch(@dir) # Update mtime

        hash.each do |key, value|
          File.open(File.join(@dir, key.to_s), "wb") do |io|
            # Marshal if the first two bytes contain non-ASCII
            if value.is_a?(String) and value[0,2] !~ HINT
              io.write(value)
            else
              Marshal.dump(value, io)
            end
          end
        end
      end

    end
  end
end
