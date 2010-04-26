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
  def sum(init = 0)
    if block_given?
      inject(init){|sum, e| sum + yield(e) }
    else
      inject(init){|sum, e| sum + e }
    end
  end unless method_defined?(:sum)

  # Collect an elements into disjoint sets, grouped by result of the block
  def group_by(collection = Hash.new{|h,k| h[k] = [] })
    inject(collection) do |hash, item|
      hash[yield(item)] << item
      hash
    end
  end unless method_defined?(:group_by)

end
