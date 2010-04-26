require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper
  
    describe "strings" do
      it "can be enclosed within single quotes" do
        ["''", "'abc'", "'abc xyz'"].test_each do |s|
          parse(:tString, s).should be_a(Parser::Nodes::TString)
        end
      end

      it "cannot be nested within single quotes" do
        node, rest = parse_some(:tString, "'abc 'xyz' tuv'")
        node.should be_a(Parser::Nodes::TString)
        rest.should == "xyz' tuv'"

        node, rest = parse_some(:tString, "'can't'")
        node.should be_a(Parser::Nodes::TString)
        rest.should == "t'"
      end

      it "can contain escaped single quotes" do
        ["''''", "'can''t'", "'abc '' xyz'"].test_each do |s|
          parse(:tString, s).should be_a(Parser::Nodes::TString)
        end
      end
      
      it "can be enclosed with $$ tags" do
        ["$$$$", "$$ abc $$", "$T$ abc $T$", "$tt$ abc $tt$"].test_each do |s|
          parse(:tString, s).should be_a(Parser::Nodes::TString)
        end
      end

      it "must have matching start and end $$ tags"

      it "can be nested within $$ tags"

      it "can embed $$ strings within single-quoted strings" do
        ["'ab $$ xyz $$ cd'", "'a $b$ c $b$ d'"].test_each do |s|
          parse(:tString, s).should be_a(Parser::Nodes::TString)
        end
      end

      it "can embed single-quote strings within $$ strings" do
        ["$$ 'abc' $$", "$ABC$ 'ab''cd' $ABC$"].test_each do |s|
          parse(:tString, s).should be_a(Parser::Nodes::TString)
        end
      end
    end

  end
end
