module Piggly
  module Util
    module Enumerable

      # Count number of elements, optionally filtered by a block
      def self.count(enum)
        if block_given?
          enum.inject(0){|count, x| count + (yield(x) ? 1 : 0) }
        else
          enum.size
        end
      end

      # Compute sum of elements, optionally transformed by a block
      def self.sum(enum, identity = 0, &block)
        if block_given?
          enum.map(&block).inject{|sum, e| sum + e } || identity
        else
          enum.inject{|sum, e| sum + e } || identity
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
