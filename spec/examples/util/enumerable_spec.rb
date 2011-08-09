require 'spec_helper'

module Piggly::Util

  describe Enumerable do
    before do
      @hash  = {:a => '%', :b => '#'}
      @array = %w(a b c d)
      @range = 'w'..'z'
      @empty = []
    end

    describe "count" do
      it "should default to `size' when no block is given" do
        Enumerable.count(@hash).should == 2
      end

      it "should count items that satisfied block" do
        Enumerable.count(@hash){ true }.should == @hash.size
        Enumerable.count(@array){ false }.should == 0
        Enumerable.count(@empty){ true }.should == @empty.size
        Enumerable.count(@range){|c| c < 'z' }.should == 3
      end
    end

    describe "sum" do
      it "should append when no block is given" do
        Enumerable.sum(@range).should == 'wxyz'
        Enumerable.sum(@array).should == 'abcd'
        Enumerable.sum(@empty).should == 0
      end

      it "should use block return value" do
        Enumerable.sum(@range){ 100 }.should == 400
        Enumerable.sum(@empty){ 100 }.should == 0
      end
    end

    describe "group_by" do
      it "should return a Hash" do
        Enumerable.group_by(@array){ nil }.should be_a(Hash)
      end

      it "should collect elements into subcollections" do
        Enumerable.group_by(@array){ :a }.should == { :a => @array }
        Enumerable.group_by(@array){|x| x <= 'b'}.should == { true => %w(a b), false => %w(c d) }
        Enumerable.group_by(@range){|x| x.to_i }.should == { 0 => %w(w x y z) }
        Enumerable.group_by(@empty){ false }.should == {}
      end
    end

    describe "index_by" do
      it "should return a Hash" do
        Enumerable.index_by(@array){ nil }.should be_a(Hash)
      end

      it "should collect only one element per group" do
        Enumerable.index_by(@array){ nil }.should == { nil => 'd' }
        Enumerable.index_by(@range){|x| x }.should == { 'w' => 'w', 'x' => 'x', 'y' => 'y', 'z' => 'z' }
      end
    end
  end

end
