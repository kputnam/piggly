require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper

    describe "white space" do
      it "includes spaces" do
        node, rest = parse_some(:tSpace, "    ")
        rest.should == ''
        node.source_text.should == "    "
      end

      it "includes tabs" do
        node, rest = parse_some(:tSpace, "\t\t")
        rest.should == ''
        node.source_text.should == "\t\t"
      end

      it "includes line feeds" do
        node, rest = parse_some(:tSpace, "\f\f")
        rest.should == ''
        node.source_text.should == "\f\f"
      end

      it "includes line breaks" do
        node, rest = parse_some(:tSpace, "\n\n")
        rest.should == ''
        node.source_text.should == "\n\n"
      end

      it "includes carriage returns" do
        node, rest = parse_some(:tSpace, "\r\r")
        rest.should == ''
        node.source_text.should == "\r\r"
      end
    end

  end
end
