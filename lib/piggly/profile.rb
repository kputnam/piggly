module Piggly

  #
  # Collection of all Tags
  #
  class Profile

    def initialize
      @by_id        = {}
      @by_cache     = {}
      @by_procedure = {}
    end

    # Register a procedure and its list of tags
    def add(procedure, tags, cache = nil)
      tags.each{|t| @by_id[t.id] = t }
      @by_cache[cache] = tags unless cache.nil?
      @by_procedure[procedure.oid] = tags
    end

    def [](object)
      case object
      when String
        @by_id[object] or
          raise "No tag with id #{object}"
      when Dumper::ReifiedProcedure,
           Dumper::SkeletonProcedure
        @by_procedure[object.oid] or
          raise "No tags for procedure #{object.signature}"
      end
    end

    # Record the execution of a coverage tag
    def ping(tag_id, value=nil)
      self[tag_id].ping(value)
    end

    # Summarizes coverage for each type of tag (branch, block, loop)
    #   @return [Hash<Symbol, Hash[:count => Integer, :percent => Float]>]
    def summary(procedure = nil)
      tags =
        if procedure
          if @by_procedure.include?(procedure.oid)
            @by_procedure[procedure.oid]
          else
            []
          end
        else
          @by_id.values
        end

      grouped = Util::Enumerable.group_by(tags){|x| x.type }

      summary = Hash.new{|h,k| h[k] = Hash.new }
      grouped.each do |type, ts|
        summary[type][:count]   = ts.size
        summary[type][:percent] = Util::Enumerable.sum(ts){|x| x.to_f } / ts.size
      end

      summary
    end

    # Resets each tag's coverage stats
    def clear
      @by_id.values.each{|x| x.clear }
    end

    # Write coverage stats to the disk cache
    def store
      @by_cache.each{|cache, tags| cache[:tags] = tags }
    end

    def empty?(tags)
      tags.all?{|t| t.to_f.zero? }
    end

    # @return [String]
    def difference(procedure, tags)
      current  = Util::Enumerable.group_by(@by_procedure[procedure.oid]){|x| x.type }
      previous = Util::Enumerable.group_by(tags){|x| x.type }

      current.default  = []
      previous.default = []

      (current.keys | previous.keys).map do |type|
        pct = Util::Enumerable.sum(current[type]){|x| x.to_f } / current[type].size -
              Util::Enumerable.sum(previous[type]){|x| x.to_f } / previous[type].size

        "#{"%+0.1f" % pct}% #{type}"
      end.join(", ")
    end

    # Build a notice processor function that records each tag execution
    #   @return [Proc]
    def notice_processor(config, stderr = $stderr)
      pattern = /WARNING:  #{config.trace_prefix} (#{Tags::AbstractTag::PATTERN})(?: (.))?/

      lambda do |message|
        if m = pattern.match(message)
          ping(m.captures[0], m.captures[1])
        else
          stderr.puts(message)
        end
      end
    end
  end

end
