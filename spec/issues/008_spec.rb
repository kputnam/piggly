require "spec_helper"

module Piggly

  describe "github issue #8" do
    include GrammarHelper

    context "with declare" do
      it "doesn't require a space before the := symbol" do
        node, rest = parse_some(:stmtDeclare, "declare a text:= 10; begin")
      # node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "doesn't require a space after the := symbol" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=10;")
        rest.should == ""
      # node.count{|e| e.assignment? }.should == 1
      end

      it "doesn't require a space after the := symbol" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=10; begin")
      # node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "allows escaped strings" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
      # node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "allows escaped octal characters" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
      # node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end
    end

    context "without declare" do
      it "doesn't require a space before the := symbol" do
        node, rest = parse_some(:statement, "a:= 10; begin")
        node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "doesn't require a space after the := symbol" do
        node = parse(:statement, "a :=10;")
        node.should be_statement
        node.count{|e| e.assignment? }.should == 1
      end

      it "doesn't require a space after the := symbol" do
        node, rest = parse_some(:statement, "a :=10; begin")
        node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "allows escaped strings" do
        node, rest = parse_some(:statement, "a :=E'\\001abc'; begin")
        node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end

      it "allows escaped octal characters" do
        node, rest = parse_some(:statement, "a :=E'\\001abc'; begin")
        node.count{|e| e.assignment? }.should == 1
        rest.should == "begin"
      end
    end

  end
end
