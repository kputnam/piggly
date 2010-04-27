require 'spec_helper'

module Piggly

  describe Parser, "statements" do
    include GrammarHelper

    describe "assignment statements" do
      it "parses successfully" do
        node = parse(:statement, "a := 10;")
        node.should be_a(Parser::Nodes::Statement)
        node.count{|e| e.is_a? Parser::Nodes::Assignment }.should == 1
        node.count{|e| e.is_a? Parser::Nodes::Assignable }.should == 1
        node.find{|e| e.named? :lval }.should be_a(Parser::Nodes::Assignable)
        node.find{|e| e.named? :rval }.should be_a(Parser::Nodes::Expression)
      end

      it "must end with a semicolon" do
        lambda { parse_some(:statement, 'a := 10') }.should raise_error
        lambda { parse(:statement, 'a := 10') }.should raise_error
      end

      it "can use := or =" do
        a = parse(:statement, "a := 10;")
        a.should be_a(Parser::Nodes::Statement)
        a.count{|e| e.is_a? Parser::Nodes::Assignment }.should == 1

        b = parse(:statement, "a = 10;")
        b.should be_a(Parser::Nodes::Statement)
        b.count{|e| e.is_a? Parser::Nodes::Assignment }.should == 1
      end

      it "can assign strings" do
        node = parse(:statement, "a := 'string';")
        rval = node.find{|e| e.named? :rval }
        rval.count{|e| e.is_a? Parser::Nodes::TString }.should == 1
      end

      it "can assign value expressions containing comments" do
        ['a := /* comment */ 100;',
         'a := 100 /* comment */;',
         'a := 10 /* comment */ + 10;'].test_each do |s|
          node = parse(:statement, s)
          rval = node.find{|e| e.named? :rval }
          rval.count{|e| e.is_a? Parser::Nodes::TComment }.should == 1
        end
      end

      it "can assign value expressions containing strings" do
        node = parse(:statement, "a := 'Hello,' || space || 'world';")
        rval = node.find{|e| e.named? :rval }
        rval.count{|e| e.is_a? Parser::Nodes::TString }.should == 2
      end

      it "can assign value expressions containing comments and strings" do
        node = parse(:statement, <<-SQL.strip)
          a := (SELECT fk, count(*), 'not a statement;'
                FROM dataset
                WHERE id > 100 /* filter out 'reserved' range */
                  AND id < 900 -- shouldn't be a string
                   OR value <> 'alpha /* no comment */;'
                GROUP BY /* pk ; 'abc' */ fk);
        SQL
        rval = node.find{|e| e.named? :rval }
        rval.count{|e| e.is_a? Parser::Nodes::TString }.should == 2
      end
    end

  end
end
