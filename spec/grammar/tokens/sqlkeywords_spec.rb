require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

module Piggly

  describe Parser, "statements" do
    include GrammarHelper

      describe "SQL keywords" do
        it "parse successfully" do
          GrammarHelper::SQLWORDS.test_each do |k|
            parse(:sqlKeyword, k).source_text.should == k
          end
        end

        it "cannot have trailing characters" do
          GrammarHelper::SQLWORDS.each do |k|
            lambda{ parse(:sqlKeyword, "#{k}abc") }.should raise_error
          end
        end

        it "cannot have preceeding characters" do
          GrammarHelper::SQLWORDS.each do |k|
            lambda{ parse(:sqlKeyword, "abc#{k}") }.should raise_error
          end
        end

        it "are terminated by symbols" do
          GrammarHelper::SQLWORDS.test_each do |k|
            node, rest = parse_some(:sqlKeyword, "#{k}+")
            node.source_text.should == k
            rest.should == '+'
          end
        end

        it "are terminated by spaces" do
          GrammarHelper::SQLWORDS.test_each do |k|
            node, rest = parse_some(:sqlKeyword, "#{k} ")
            node.source_text.should == k
            rest.should == ' '
          end
        end
      end

  end
end
