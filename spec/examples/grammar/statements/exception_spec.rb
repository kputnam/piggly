require 'spec_helper'

module Piggly
  describe Parser, "control structures" do
    include GrammarHelper

    describe "exceptions" do
      describe "raise" do
        it "parses successfully" do
          node, rest = parse_some(:statement, "RAISE EXCEPTION 'message';")
          node.should be_statement
          rest.should == ''
        end

        it "handles exception" do
          node = parse(:statement, "RAISE EXCEPTION 'message';")
          node.count{|e| e.is_a?(Parser::Nodes::Throw) }.should == 1
          node.count{|e| e.is_a?(Parser::Nodes::Raise) }.should == 0
        end

        it "handles events" do
          %w(WARNING LOG INFO NOTICE DEBUG).each do |event|
            node = parse(:statement, "RAISE #{event} 'message';")
            node.count{|e| e.is_a?(Parser::Nodes::Throw) }.should == 0
            node.count{|e| e.is_a?(Parser::Nodes::Raise) }.should == 1
          end
        end
      end

      describe "catch" do
        before do
          @text = 'BEGIN a := 10; EXCEPTION WHEN cond THEN b := 10; WHEN cond THEN b := 20; END;'
        end

        it "parses successfully" do
          node, rest = parse_some(:statement, @text)
          node.should be_statement
          rest.should == ''
        end

        it "has Catch node" do
          node = parse(:statement, @text)
          catches = node.select{|e| e.is_a?(Parser::Nodes::Catch) }
          catches.size.should == 2

          catches[0].count{|e| e.named?(:cond) and e.expression? }.should == 1
          catches[1].count{|e| e.named?(:cond) and e.expression? }.should == 1
        end
      end
    end
  end
end
