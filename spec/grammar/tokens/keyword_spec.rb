require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper
  
    describe "keywords" do
      it "parse successfully" do
        GrammarHelper::KEYWORDS.test_each do |k|
          parse(:keyword, k).should be_a(TKeyword)
        end
      end

      it "cannot have trailing characters" do
        GrammarHelper::KEYWORDS.each do |k|
          lambda{ parse(:keyword, "#{k}abc") }.should raise_error
        end
      end

      it "cannot have preceeding characters" do
        GrammarHelper::KEYWORDS.each do |k|
          lambda{ parse(:keyword, "abc#{k}") }.should raise_error
        end
      end

      it "are terminated by symbols" do
        GrammarHelper::KEYWORDS.test_each do |k|
          node, rest = parse_some(:keyword, "#{k}+")
          node.should be_a(TKeyword)
          rest.should == '+'
        end
      end

      it "are terminated by spaces" do
        GrammarHelper::KEYWORDS.test_each do |k|
          node, rest = parse_some(:keyword, "#{k} ")
          node.should be_a(TKeyword)
          rest.should == ' '
        end
      end
    end

  end
end