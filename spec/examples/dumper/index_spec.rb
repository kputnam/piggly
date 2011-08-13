require "spec_helper"

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
          @first  = Dumper::ReifiedProcedure.from_hash \
            "oid"    => "1000",
            "name"   => "iterate",
            "source" => "FIRST PROCEDURE SOURCE CODE"

          @second = Dumper::ReifiedProcedure.from_hash \
            "oid"    => "2000",
            "name"   => "login",
            "source" => "SECOND PROCEDURE SOURCE CODE"

          File.stub(:read).with(@first.source_path(@config)).
            and_return(@first.source(@config))

          File.stub(:read).with(@second.source_path(@config)).
            and_return(@second.source(@config))

          File.stub(:read).with(@index.path).
            and_return(YAML.dump([@first, @second]))
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
      def q(*ns)
        Dumper::QualifiedName.new(*ns)
      end

      before do
        @procedure = mock(:oid  => 1,
                          :name => q("public", "foo"),
                          :type => q("private", "int"),
                          :arg_modes => ["in", "in"],
                          :arg_names => [],
                          :arg_types => [q("private", "int"), q("private", "varchar")])
      end

      context "when name is unique" do
        context "and there is only one schema" do
          before do
            @index.stub(:procedures =>
              [ @procedure,
                mock(:oid  => 2,
                     :name => q("public", "bar"),
                     :type => q("private", "int"),
                     :arg_modes => ["in"],
                     :arg_names => [],
                     :arg_types => []) ])
          end

          it "specifies schema.name" do
            @index.label(@procedure).should == "foo"
          end
        end

        context "and there is more than one schema" do
          before do
            @index.stub(:procedures =>
              [ @procedure,
                mock(:oid  => 2,
                     :name => q("schema", "foo"),
                     :type => q("private", "int"),
                     :arg_modes => ["in"],
                     :arg_names => [],
                     :arg_types => []) ])
          end

          it "specifies schema.name" do
            @index.label(@procedure).should == "public.foo"
          end
        end
      end

      context "when name is not unique" do
        context "and schema.name is unique" do
          before do
            @index.stub(:procedures =>
              [ @procedure,
                mock(:oid  => 2,
                     :name => q("schema", "foo"),
                     :type => q("private", "int"),
                     :arg_modes => ["in"],
                     :arg_names => [],
                     :arg_types => []) ])
          end

          it "specifies schema.name" do
            @index.label(@procedure).should == "public.foo"
          end
        end

        context "and schema.name is not unique" do
          context "but argument types are unique" do
            before do
              @index.stub(:procedures =>
                [ @procedure,
                  mock(:oid  => 2,
                       :name => q("public", "foo"),
                       :type => q("private", "int"),
                       :arg_modes => ["in"],
                       :arg_names => [],
                       :arg_types => []) ])
            end

            it "specifies schema.name(types)" do
              @index.label(@procedure).should ==
                "foo(private.int, private.varchar)"
            end
          end

          context "and argument types are not unique" do
            context "but argument modes are unique" do
              before do
                @index.stub(:procedures =>
                  [ @procedure,
                    mock(:oid  => 2,
                         :name => q("public", "foo"),
                         :type => q("private", "int"),
                         :arg_modes => ["out", "out"],
                         :arg_names => [],
                         :arg_types => [q("private", "int"), q("private", "varchar")]) ])
              end

              it "specifies schema.name(types and modes)" do
                @index.label(@procedure).should ==
                  "foo(in private.int, in private.varchar)"
              end
            end
          end
        end
      end
    end

  end

end
