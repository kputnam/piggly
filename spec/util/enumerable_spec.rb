require 'spec_helper'

module Piggly

  describe Enumerable do
    before do
      @hash  = {:a => '%', :b => '#'}
      @array = %w(a b c d)
      @range = 'w'..'z'
      @empty = []
    end

    describe "count" do
      it "should default to `size' when no block is given" do
        @hash.should_receive(:size).and_return(100)
        @hash.count.should == 100
      end

      it "should count items that satisfied block" do
        @hash.count{ true }.should == @hash.size
        @array.count{ false }.should == 0
        @empty.count{ true }.should == @empty.size
        @range.count{|c| c < 'z' }.should == 3
      end
    end

    describe "sum" do
      it "should append when no block is given" do
        @range.sum.should == 'wxyz'
        @array.sum.should == 'abcd'
        @empty.sum.should == 0
      end

      it "should use block return value" do
        @range.sum{ 100 }.should == 400
        @empty.sum{ 100 }.should == 0
      end
    end

    describe "group_by" do
      it "should return a Hash" do
        @array.group_by{ nil }.should be_a(Hash)
      end

      it "should collect elements into subcollections" do
        @array.group_by{ :a }.should == { :a => @array }
        @array.group_by{|x| x <= 'b'}.should == { true => %w(a b), false => %w(c d) }
        @range.group_by(&:to_i).should == { 0 => %w(w x y z) }
        @empty.group_by{ false }.should == {}
      end
    end

    describe "index_by" do
      it "should return a Hash" do
        @array.index_by{ nil }.should be_a(Hash)
      end

      it "should collect only one element per group" do
        @array.index_by{ nil }.should == { nil => 'd' }
        @range.index_by{|x| x }.should == { 'w' => 'w', 'x' => 'x', 'y' => 'y', 'z' => 'z' }
      end
    end
  end

end
