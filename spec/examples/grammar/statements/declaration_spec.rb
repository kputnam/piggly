require 'spec_helper'

module Piggly

  describe Parser, "statements" do
    include GrammarHelper

    describe "single variable declarations" do
      it "parse successfully" do
        node = parse(:stmtDeclare, "declare t text;")
        node.count{|e| e.is_a? Parser::Nodes::TIdentifier }.should == 1
        node.count{|e| e.is_a? Parser::Nodes::TDatatype }.should == 1
      end

      it "allows an initial assignment" do
        node = parse(:stmtDeclare, "declare a text := 10;")
      end

      it "doesn't require a space after the := symbol (GH #8)" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=10; begin")
        rest.should == "begin"
      end

      it "allows escaped strings (GH #8)" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
        rest.should == "begin"
      end

      it "allows escaped octal characters (GH #8)" do
        node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
        rest.should == "begin"
      end
    end

  end
end
