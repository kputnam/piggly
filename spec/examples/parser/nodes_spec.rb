require 'spec_helper'

module Piggly

  # load support code
  Parser.parser

  describe NodeClass do
    describe "source_text"
    describe "named?"

    context "untagged node" do
      describe "tagged?"
      describe "tag_id"
      describe "tag"
    end

    context "tagged node" do
      describe "tagged?"
      describe "tag_id"
      describe "tag"
    end
  end

  describe Parser::Nodes::Expression do
    describe "tag" do
      context "untagged node" do
        context "named :cond" do
          context "with parent.while?"
          context "with parent.loop?"
          context "with parent.branch?"
          context "with some other type of parent"
        end

        context "not named :cond" do
        end
      end
    end
  end

  describe Parser::Nodes::Sql do
    describe "tag" do
      context "untagged node" do
        context "named :cond" do
          context "with parent.for?"
          context "with some other parent"
        end

        context "not named :cond"
      end
    end
  end

  describe Parser::Nodes::TKeyword do
    describe "tag" do
      context "untagged node" do
        context "named :cond" do
          context "with parent.loop?"
          context "with some other parent"
        end

        context "not named :cond"
      end
    end
  end

  describe Parser::Nodes::Terminal do
  end

  describe Parser::Nodes::NotImplemented do
  end

end
