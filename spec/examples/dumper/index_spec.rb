require 'spec_helper'

module Piggly

  describe Dumper::Index do
    before do
      # make sure not to create directories all over the file system during the test
      Config.stub(:mkpath).and_return{|root, file| File.join(root, file) }

      @config = Config.new
      @index  = Dumper::Index.new(@config)
    end

    context "when cache file doesn't exist" do
      it "is empty" do
        File.should_receive(:exists?).with(@index.path).and_return(false)
        @index.procedures.should be_empty
      end
    end

    context "when cache file exists" do
      before do
        File.stub(:exists?).with(@index.path).and_return(true)
      end

      context "when the cache index file is empty" do
        it "is empty" do
          File.should_receive(:read).with(@index.path).and_return([].to_yaml)
          @index.procedures.should be_empty
        end
      end

      context "when the cache index file has two entries" do
        before do
          Piggly::Config.stub(:identify_procedures_using).and_return('oid')

          @first  = Dumper::ReifiedProcedure.from_hash \
            'oid'    => '1000',
            'name'   => 'iterate',
            'source' => 'FIRST PROCEDURE SOURCE CODE'

          @second = Dumper::ReifiedProcedure.from_hash \
            'oid'    => '2000',
            'name'   => 'login',
            'source' => 'SECOND PROCEDURE SOURCE CODE'

          File.stub(:read).with(@first.source_path(@config)).and_return(@first.source(@config))
          File.stub(:read).with(@second.source_path(@config)).and_return(@second.source(@config))
          File.stub(:read).with(@index.path).and_return([@first, @second].to_yaml)
        end

        it "has two procedures" do
          @index.procedures.should have(2).things
        end

        it "is indexed by identifier" do
          @index[@first.identifier].identifier.should == @first.identifier
          @index[@second.identifier].identifier.should == @second.identifier
        end

        it "reads each procedure's source_path" do
          @index[@first.identifier].source(@config).should == @first.source(@config)
          @index[@second.identifier].source(@config).should == @second.source(@config)
        end

        context "when the procedures used to be identified using another method" do
          it "renames each procedure using the current identifier"
          it "updates the index with the current identified_using"
          it "writes the updated index to disk"
        end
      end
    end

    describe "update" do
      it "caches the source of new procedures"
      it "updates the cached source of updated procedures"
      it "purges the cached source of outdated procedures"
      it "writes the cache index to disk"
      it "does not write procedure source code within the cache index"
    end

    describe "label" do
      context "when procedure name is unique" do
        it "specifies procedure name"
      end

      context "when procedure name is not unique" do
        context "but procedure name and namespace are unique" do
          it "specifies procedure name and namespace"
        end

        context "and when procedure name and namespace are not unique" do
          context "but procedure name and argument types are unique" do
            it "specifies procedure name and argument types"
          end

          context "and when procedure name and argument types are not unique" do
            it "specifies procedure name, namespace, and argument types"
          end
        end
      end
    end

  end

end
