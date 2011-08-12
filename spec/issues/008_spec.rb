require "spec_helper"

module Piggly

  describe "github issue #8" do
    include GrammarHelper

    it "doesn't require a space after the := symbol" do
      node = parse(:statement, "a :=10;")
      node.should be_statement
      node.count{|e| e.assignment? }.should == 1

      node.find{|e| e.named? :lval }.should be_a(Parser::Nodes::Assignable)
      node.find{|e| e.named? :rval }.should be_expression
    end

    it "doesn't require a space after the := symbol" do
      node, rest = parse_some(:stmtDeclare, "declare a text :=10; begin")
      rest.should == "begin"
    end

    it "allows escaped strings" do
      node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
      rest.should == "begin"
    end

    it "allows escaped octal characters" do
      node, rest = parse_some(:stmtDeclare, "declare a text :=E'\\001abc'; begin")
      rest.should == "begin"
    end

  end
end
