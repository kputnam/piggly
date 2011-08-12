require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper

    describe "labels" do
      it "must be enclosed in << and >>" do
        ['', 'a', 'abc', '<< a', 'a >>'].test_each do |s|
          lambda{ parse(:tLabelDefinition, s) }.should raise_error
        end
      end

      it "can have space padding" do
        %w[a abc _].map{|s| "<< #{s} >>" }.test_each do |s|
          parse(:tLabelDefinition, s).should be_label
        end
      end

      it "can have no space padding" do
        %w[a abc _].map{|s| "<<#{s}>>" }.test_each do |s|
          parse(:tLabelDefinition, s).should be_label
        end
      end

      it "cannot be multiple unquoted words" do
        ["<< a b >>", "<< ab cd >>"].test_each do |s|
          lambda{ parse(:tLabelDefinition, s) }.should raise_error
        end
      end

      it "can be enclosed in double quotes" do
        ['<< "a" >>', '<< "a b" >>', '<< "ab cd" >>'].test_each do |s|
          parse(:tLabelDefinition, s).should be_label
        end
      end
    end

  end
end
