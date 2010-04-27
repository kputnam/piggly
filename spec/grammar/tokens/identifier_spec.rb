require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper
    
    describe "identifiers" do
      it "cannot be a keyword" do
        GrammarHelper::KEYWORDS.test_each do |s|
          lambda{ parse(:tIdentifier, s) }.should raise_error
        end
      end

      it "can be quoted keyword" do
        GrammarHelper::KEYWORDS.map{|s| '"' + s + '"' }.test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end
      end

      it "can begin with a keyword" do
        GrammarHelper::KEYWORDS.select{|s| s =~ /^[a-z]/i }.map{|s| "#{s}xyz" }.test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end

        GrammarHelper::KEYWORDS.select{|s| s =~ /^[a-z]/i }.map{|s| "#{s}_xyz" }.test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end
      end

      it "can end with a keyword" do
        GrammarHelper::KEYWORDS.select{|s| s =~ /^[a-z]/i }.map{|s| "xyz#{s}" }.test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end

        GrammarHelper::KEYWORDS.select{|s| s =~ /^[a-z]/i }.map{|s| "xyz_#{s}" }.test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end
      end

      it "can be one single character" do
        %w[_ a b c d e f g h i j k l m n o p q r s t u v w x y z].test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end
      end

      it "can contain underscores" do
        %w[_abc abc_ ab_c a_bc ab_cd ab_c_d a_bc_d ab_c_d a_b_c_d a__b__c__d].test_each do |s|
          parse(:tIdentifier, s).should be_a(Parser::Nodes::TIdentifier)
        end
      end

      it "can contain numbers" do
        parse(:tIdentifier, 'foo9000').should be_a(Parser::Nodes::TIdentifier)
      end
    end

  end
end
