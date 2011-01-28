require 'spec_helper'

module Piggly::Util

  describe File, "cache invalidation" do
    before do
      mtime = Hash['a' => 1,  'b' => 2,  'c' => 3]
      ::File.stub(:mtime).and_return{|f| mtime.fetch(f) }
      ::File.stub(:exists?).and_return{|f| mtime.include?(f) }
    end

    it "invalidates non-existant cache file" do
      File.stale?('d', 'a').should == true
      File.stale?('d', 'a', 'b').should == true
    end

    it "performs validation using file mtimes" do
      File.stale?('c', 'b').should_not be_true
      File.stale?('c', 'a').should_not be_true
      File.stale?('c', 'b', 'a').should_not be_true
      File.stale?('c', 'a', 'b').should_not be_true

      File.stale?('b', 'a').should_not be_true
      File.stale?('b', 'c').should be_true
      File.stale?('b', 'a', 'c').should be_true
      File.stale?('b', 'c', 'a').should be_true

      File.stale?('a', 'b').should be_true
      File.stale?('a', 'c').should be_true
      File.stale?('a', 'b', 'c').should be_true
      File.stale?('a', 'c', 'b').should be_true
    end

    it "assumes sources exist" do
      lambda{ File.stale?('a', 'd') }.should raise_error(StandardError)
      lambda{ File.stale?('c', 'a', 'x') }.should raise_error(StandardError)
    end
  end  

end
