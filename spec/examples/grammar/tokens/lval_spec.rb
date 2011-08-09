require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper

    describe "l-values" do
      it "can be a simple identifier" do
        parse(:lValue, 'id').should be_a(Parser::Nodes::Assignable)
      end

      it "can be an attribute accessor" do
        parse(:lValue, 'record.id').should be_a(Parser::Nodes::Assignable)
        parse(:lValue, 'public.dataset.id').should be_a(Parser::Nodes::Assignable)
      end

      it "can use quoted attributes" do
        parse(:lValue, 'record."ID"').should be_a(Parser::Nodes::Assignable)
        parse(:lValue, '"schema name"."table name"."column name"').should be_a(Parser::Nodes::Assignable)
      end
      
      it "can be an array accessor" do
        parse(:lValue, 'names[0]').should be_a(Parser::Nodes::Assignable)
        parse(:lValue, 'names[1000]').should be_a(Parser::Nodes::Assignable)
      end

      it "can contain comments in array accessors" do
        node = parse(:lValue, 'names[3 /* comment */]')
        node.should be_a(Parser::Nodes::Assignable)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }
        
        node = parse(:lValue, "names[9 -- comment \n]")
        node.should be_a(Parser::Nodes::Assignable)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }
      end

      it "can be an array accessed by another l-value" do
        parse(:lValue, 'names[face.id]').should be_a(Parser::Nodes::Assignable)
      end

      it "can be a nested array access"
        # names[faces[0].id].id doesn't work because it requires context-sensitivity [faces[0]
      
      it "can be a multi-dimensional array access" do
        parse(:lValue, 'data[10][2][0]').should be_a(Parser::Nodes::Assignable)
      end
    end

  end
end
