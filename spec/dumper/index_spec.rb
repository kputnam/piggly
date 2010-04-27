require 'spec_helper'

module Piggly

describe Dumper::Index do
  before do
    # make sure not to create directories all over the file system during the test
    Config.stub(:mkpath).and_return{|root, file| File.join(root, file) }
  end

  context "when path doesn't exist" do
    before do
      File.stub(:exists?).with(Dumper::Index.path).and_return(false)
      @index = Dumper::Index.new
    end

    it "is empty" do
      @index.procedures.should be_empty
    end
  end

  context "when path does exist" do
    before do
      File.stub(:exists?).with(Dumper::Index.path).and_return(true)
    end

    context "when the cache file is empty" do
      before do
        File.stub(:read).with(Dumper::Index.path).and_return([].to_yaml)
        @index = Dumper::Index.new
      end

      it "is empty" do
        @index.procedures.should be_empty
      end
    end

    context "when the cache file has two entries" do
      before do
        @first  = Dumper::Procedure.from_hash('oid' => '1000', 'name' => 'iterate', 'source' => 'FIRST PROCEDURE SOURCE CODE')
        @second = Dumper::Procedure.from_hash('oid' => '2000', 'name' => 'login',   'source' => 'SECOND PROCEDURE SOURCE CODE')

        File.stub(:read).with(@first.source_path).and_return(@first.source)
        File.stub(:read).with(@second.source_path).and_return(@second.source)
        File.stub(:read).with(Dumper::Index.path).and_return([@first, @second].to_yaml)

        @index = Dumper::Index.new
      end

      it "should have two procedures" do
        @index.procedures.should have(2).things
      end

      it "should be indexed by procedure oid" do
        @index[@first.oid].oid.should == @first.oid
        @index[@second.oid].oid.should == @second.oid
      end

      it "should read each procedures source_path" do
        @index[@first.oid].source.should == @first.source
        @index[@second.oid].source.should == @second.source
      end
    end
  end

end

end
