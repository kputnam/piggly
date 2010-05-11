module Enumerable

  # Count number of elements, optionally filtered by a block
  def count
    if block_given?
      inject(0){|count, x| count + (yield(x) ? 1 : 0) }
    else
      size
    end
  end unless method_defined?(:count)

  # Compute sum of elements, optionally transformed by a block
  def sum(identity = 0, &block)
    if block_given?
      map(&block).inject{|sum, e| sum + e } || identity
    else
      inject{|sum, e| sum + e } || identity
    end
  end unless method_defined?(:sum)

  # Collect an elements into disjoint sets, grouped by result of the block
  def group_by(collection = Hash.new{|h,k| h[k] = [] })
    inject(collection) do |hash, item|
      hash[yield(item)] << item
      hash
    end
  end unless method_defined?(:group_by)

  def index_by(collection = Hash.new)
    inject(collection) do |hash, item|
      hash.update(yield(item) => item)
    end
  end unless method_defined?(:index_by)

end
