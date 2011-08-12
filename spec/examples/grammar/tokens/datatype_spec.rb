require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper

    describe "data types" do
      it "can consist of a single word" do
        %w[int boolean char varchar text date timestamp record].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end
      
      it "can have parameterized types" do
        ["numeric(10,2)", "decimal(12,4)", "char(1)", "varchar(100)"].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "can end in %ROWTYPE" do
        %w[users%rowtype].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "can have namespace notation" do
        %w[public.users namespace.relation%rowtype].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "can consist of several words" do
        ["timestamp with time zone", "character varying"].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "can specify arrays" do
        ["integer[]", "varchar(10)[]", "numeric(10,2)[]", "timestamp without time zone[]"].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "can specify multi-dimensional" do
        ["integer[][]", "char(1)[][]", "character varying[][]"].test_each do |s|
          parse(:tType, s).should be_datatype
        end
      end

      it "are terminated by symbol outside of parentheses" do
        node, rest = parse_some(:tType, "character varying, ")
        node.should be_datatype
        rest.should == ', '
      end
    end

  end
end
