module Piggly

  #
  # Collection of all Tags
  #
  class Profile
    PATTERN = /WARNING:  #{Piggly::Config.trace_prefix} (#{Piggly::Tags::AbstractTag::PATTERN})(?: (.))?/

    class << self
      def instance
        @instance ||= new
      end

      # Build a notice processor function that records each tag execution
      def notice_processor
        proc do |message|
          if m = PATTERN.match(message)
            instance.ping(m.captures[0], m.captures[1])
          else
            STDERR.puts message
          end
        end
      end
    end

    attr_reader :by_id, :by_procedure

    def initialize
      @by_id        = {}
      @by_cache     = {}
      @by_procedure = {}
    end

    # Register a procedure and its list of tags
    def add(procedure, tags, cache = nil)
      tags.each{|t| @by_id[t.id] = t }
      @by_cache[cache] = tags if cache
      @by_procedure[procedure.oid] = tags
    end

    def [](object)
      case object
      when String
        @by_id[object] or
          raise "No tag with id #{object}"
      when Piggly::Dumper::Procedure
        @by_procedure[object.oid] or
          raise "No tags for procedure #{object.signature}"
      end
    end

    # Record the execution of a coverage tag
    def ping(tag_id, value=nil)
      self[tag_id].ping(value)
    end

    # Summarizes coverage for each type of tag (branch, block, loop)
    def summary(procedure = nil)
      summary = Hash.new{|h,k| h[k] = Hash.new }

      if procedure
        if @by_procedure.include?(procedure.oid)
          grouped = @by_procedure[procedure.oid].group_by(&:type)
        else
          grouped = {}
        end
      else
        grouped = @by_id.values.group_by(&:type)
      end

      grouped.each do |type, ts|
        summary[type][:count]   = ts.size
        summary[type][:percent] = ts.sum(&:to_f) / ts.size
      end

      summary
    end

    # Resets each tag's coverage stats
    def clear
      @by_id.each{|id, tag| tag.clear }
    end

    # Write coverage stats to the disk cache
    def store
      @by_cache.each{|cache, tags| cache[:tags] = tags }
    end

  end
end
