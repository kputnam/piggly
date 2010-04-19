module Piggly

  #
  # Collection of all Tags
  #
  class Profile
    PATTERN = /WARNING:  #{Config.trace_prefix} (#{Tag::PATTERN})(?: (.))?/

    class << self

      # Build a notice processor function that records each tag execution
      def notice_processor
        proc do |message|
          if m = PATTERN.match(message)
            ping(m.captures[0], m.captures[1])
          else
            STDERR.puts message
          end
        end
      end

      # Register a source file (path) with its list of tags
      def add(path, tags, cache = nil)
        tags.each{|t| by_id[t.id] = t }
        by_file[path]  = tags
        by_cache[cache] = tags if cache
      end

      # Each tag indexed by unique ID
      def by_id
        @by_id ||= Hash.new
      end

      # Each tag grouped by source file path
      def by_file
        @by_file ||= Hash.new
      end

      # Each tag grouped by FileCache
      def by_cache
        @by_cache ||= Hash.new
      end

      # Record the execution of a coverage tag
      def ping(tag_id, value=nil)
        if tag = by_id[tag_id]
          tag.ping(value)
        else
          raise "No tag with id #{tag_id}, perhaps the proc was not compiled with Piggly::Installer.trace_proc, or it has been recompiled with new tag IDs."
        end
      end

      # Summarizes coverage for each type of tag (branch, block, loop)
      def summary(file = nil)
        summary = Hash.new{|h,k| h[k] = Hash.new }

        if file
          if by_file.include?(file)
            grouped = by_file[file].group_by{|t| t.type }
          else
            grouped = {}
          end
        else
          grouped = map.group_by{|t| t.type }
        end

        grouped.each do |type, ts|
          summary[type][:count]   = ts.size
          summary[type][:percent] = ts.sum{|t| t.to_f } / ts.size
        end

        summary
      end

      # Resets each tag's coverage stats
      def clear
        by_id.values.each{|t| t.clear }
      end

      # Write each tag's coverage stats to the disk cache
      def store
        by_cache.each{|cache, tags| cache[:tags] = tags }
      end

    end
  end
end
