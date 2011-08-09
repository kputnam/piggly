require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper

    describe "comments" do
      it "can begin with -- and terminate at EOF" do
        GrammarHelper::COMMENTS.map{|s| "-- #{s}" }.test_each do |s|
          parse(:tComment, s).should be_a(Parser::Nodes::TComment)
        end
      end

      it "can begin with -- and terminate at line ending" do
        GrammarHelper::COMMENTS.map{|s| "-- #{s}\n" }.test_each do |s|
          parse(:tComment, s).should be_a(Parser::Nodes::TComment)
        end

        GrammarHelper::COMMENTS.map{|s| "-- #{s}\n\n" }.test_each do |s|
          node, rest = parse_some(:tComment, s)
          node.should be_a(Parser::Nodes::TComment)
          rest.should == "\n"
        end

        GrammarHelper::COMMENTS.map{|s| "-- #{s}\nremaining cruft\n" }.test_each do |s|
          node, rest = parse_some(:tComment, s)
          node.should be_a(Parser::Nodes::TComment)
          rest.should == "remaining cruft\n"
        end
      end

      it "can be /* c-style */" do
        GrammarHelper::COMMENTS.map{|s| "/* #{s} */" }.test_each do |s|
          parse(:tComment, s).should be_a(Parser::Nodes::TComment)
        end
      end

      it "terminates after */ marker" do
        GrammarHelper::COMMENTS.map{|s| "/* #{s} */remaining cruft\n" }.test_each do |s|
          node, rest = parse_some(:tComment, s)
          node.should be_a(Parser::Nodes::TComment)
          rest.should == "remaining cruft\n"
        end
      end

      it "cannot be nested" do
        node, rest = parse_some(:tComment, "/* nested /*INLINE*/ comments */")
        node.should be_a(Parser::Nodes::TComment)
        rest.should == " comments */"

        node, rest = parse_some(:tComment, "-- nested -- line comments")
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 1
        rest.should == ''
      end
    end

  end
end
