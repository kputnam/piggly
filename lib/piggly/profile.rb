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
            $stderr.puts message
          end
        end
      end
    end

    attr_reader :by_id, :by_cache, :by_procedure

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
        by_id[object] or
          raise "No tag with id #{object}"
      when Piggly::Dumper::Procedure
        by_procedure[object.oid] or
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
        if by_procedure.include?(procedure.oid)
          grouped = by_procedure[procedure.oid].group_by{|x| x.type }
        else
          grouped = {}
        end
      else
        grouped = by_id.values.group_by{|x| x.type }
      end

      grouped.each do |type, ts|
        summary[type][:count]   = ts.size
        summary[type][:percent] = ts.sum{|x| x.to_f } / ts.size
      end

      summary
    end

    # Resets each tag's coverage stats
    def clear
      by_id.values.each{|x| x.clear }
    end

    # Write coverage stats to the disk cache
    def store
      by_cache.each{|cache, tags| cache[:tags] = tags }
    end

    def empty?(tags)
      tags.all?{|t| t.to_f == 0 }
    end

    def difference(procedure, tags)
      current  = by_procedure[procedure.oid].group_by{|x| x.type }
      previous = tags.group_by{|x| x.type }

      current.default = []
      previous.default = []

      (current.keys | previous.keys).map do |type|
        pct = current[type].sum{|x| x.to_f } / current[type].size -
              previous[type].sum{|x| x.to_f } / previous[type].size

        "#{'%+0.1f' % pct}% #{type}"
      end.join(', ')
    end

  end
end
