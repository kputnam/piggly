module Piggly
  module Util
    module Enumerable

      # Count number of elements, optionally filtered by a block
      def self.count(enum)
        if block_given?
          enum.inject(0){|count,e| yield(e) ? count + 1 : count }
        else
          enum.length
        end
      end

      # Compute sum of elements, optionally transformed by a block
      def self.sum(enum, default = 0, &block)
        enum = enum.to_a
        return default if enum.empty?

        head, *tail = enum

        if block_given?
          tail.inject(yield(head)){|sum,e| sum + yield(e) }
        else
          tail.inject(head){|sum,e| sum + e }
        end
      end

      # Collect an elements into disjoint sets, grouped by result of the block
      def self.group_by(enum, collection = Hash.new{|h,k| h[k] = [] })
        enum.inject(collection) do |hash, item|
          hash[yield(item)] << item
          hash
        end
      end

      def self.index_by(enum, collection = Hash.new)
        enum.inject(collection) do |hash, item|
          hash.update(yield(item) => item)
        end
      end

    end
  end
end
