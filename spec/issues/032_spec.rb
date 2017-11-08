require "spec_helper"

module Piggly
  describe "github issue #32" do

    # note: both -r always subtracts and -s always adds
    # from left-to-right.
    #
    # if the first filter is -s, then the set starts empty
    # and -s adds to it.
    #
    # if the first filter is -r, then the set starts with
    # all procedures and -r removes from it.

    def result(args)
      index = double("index", :procedures => [
                double("public.a", :name => "public.a"),
                double("public.b", :name => "public.b"),
                double("public.c", :name => "public.c"),
                double("public.d", :name => "public.d")])
      config = Command::Trace.configure(args.dup)
      result = Command::Trace.filter(config, index)
      result.map(&:name).sort
    end
    
    context "with one -s argument" do
      let(:args) { %w(-s public.c) }

      it "selects matching procs" do
        result(args).should == ["public.c"]
      end
    end

    context "with -s regular expression" do
      let(:args) { %w(-s /public.[bcd]/) }

      it "selects matching procs" do
        result(args).should == [
          "public.b",
          "public.c",
          "public.d"]
      end
    end

    context "with two -s arguments" do
      let(:args) { %w(-s public.b -s public.d) }

      it "adds matching procs" do
        result(args).should == [
          "public.b",
          "public.d"]
      end
    end

    context "with one -r argument" do
      let(:args) { %w(-r public.c) }

      it "rejects matching procs" do
        result(args).should == [
          "public.a",
          "public.b",
          "public.d"]
      end
    end

    context "with two -r arguments" do
      let(:args) { %w(-r public.b -r public.d) }

      it "subtracts rejected procs" do
        result(args).should == [
          "public.a",
          "public.c"]
      end
    end

    context "with -s then -r" do
      let(:args) { %w(-s /\.[abc]/ -r public.b -r public.d) }

      it "-r removes from -s matches" do
        result(args).should == [
          "public.a",
          "public.c"]
      end
    end

    context "with -r then -s" do
      let(:args) { %w(-r /\.[bc]/ -s public.b -s public.a) }

      it "-s adds to -r non-matches" do
        result(args).should == [
          "public.a",
          "public.b",
          "public.d"]
      end
    end

  end
end
