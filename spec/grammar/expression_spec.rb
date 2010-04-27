require 'spec_helper'

module Piggly
  describe Parser, "expressions" do
    include GrammarHelper

    describe "expressionUntilSemiColon" do
      it "does not consume semicolon" do
        # parser stops in front of THEN and dies
        lambda{ parse(:expressionUntilSemiColon, 'abc;') }.should raise_error

        node, rest = parse_some(:expressionUntilSemiColon, 'abc; xyz')
        rest.should == '; xyz'
      end

      it "can be a blank expression" do
        node, rest = parse_some(:expressionUntilSemiColon, ';')
        node.should be_a(Parser::Nodes::Expression)
        node.source_text.should == ''
        rest.should == ';'
      end

      it "can be a comment" do
        node, rest = parse_some(:expressionUntilSemiColon, "/* comment */;")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 1

        node, rest = parse_some(:expressionUntilSemiColon, "-- comment\n;")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 1
      end

      it "can be a string" do
        node, rest = parse_some(:expressionUntilSemiColon, "'string';")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1

        node, rest = parse_some(:expressionUntilSemiColon, "$$ string $$;")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an arithmetic expression" do
        node, rest = parse_some(:expressionUntilSemiColon, "10 * (3 + x);")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an SQL statement" do
        node, rest = parse_some(:expressionUntilSemiColon, "SELECT id FROM dataset;")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an expression with comments embedded" do
        node, rest = parse_some(:expressionUntilSemiColon, <<-SQL)
          SELECT id                    -- primary key ;
          FROM "dataset" /* ; */       -- previous comments shouldn't terminate expression
          WHERE value IS /*NOT*/ NULL;
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
      end

      it "can be an expression with strings and comments embedded" do
        node, rest = parse_some(:expressionUntilSemiColon, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */;
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an expression with strings embedded" do
        node, rest = parse_some(:expressionUntilSemiColon, <<-SQL)
          SELECT id, created_at
          FROM "dataset"
          WHERE value IS NOT NULL
            AND value <> '; this should not terminate expression'
            AND created_at = '2001-01-01';
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 2
      end

      it "should combine trailing whitespace into 'tail' node" do
        node, rest = parse_some(:expressionUntilSemiColon, "a := x + y  \t;")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == "  \t"
      end

      it "should combine trailing comments into 'tail' node" do
        node, rest = parse_some(:expressionUntilSemiColon, "a := x + y /* note -- comment */;")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == ' /* note -- comment */'

        node, rest = parse_some(:expressionUntilSemiColon, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */;
        SQL
        node.tail.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 2
      end
    end

    describe "expressionUntilThen" do
      it "does not consume THEN token" do
        # parser stops in front of THEN and dies
        lambda{ parse(:expressionUntilThen, 'abc THEN') }.should raise_error

        node, rest = parse_some(:expressionUntilThen, 'abc THEN xyz')
        rest.should == 'THEN xyz'
      end

      it "cannot be a blank expression" do
        lambda{ parse_some(:expressionUntilThen, ' THEN') }.should raise_error
      end

      it "cannot be a comment" do
        lambda{ parse_some(:expressionUntilThen, "/* comment */ THEN") }.should raise_error
        lambda{ parse_some(:expressionUntilThen, "-- comment\n THEN") }.should raise_error
      end

      it "can be a string" do
        node, rest = parse_some(:expressionUntilThen, "'string' THEN")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1

        node, rest = parse_some(:expressionUntilThen, "$$ string $$ THEN")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an arithmetic expression" do
        node, rest = parse_some(:expressionUntilThen, "10 * (3 + x) THEN")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an SQL statement" do
        node, rest = parse_some(:expressionUntilThen, "SELECT id FROM dataset THEN")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an expression with comments embedded" do
        node, rest = parse_some(:expressionUntilThen, <<-SQL)
          SELECT id                    -- primary key  THEN
          FROM "dataset" /*  THEN */       -- previous comments shouldn't terminate expression
          WHERE value IS /*NOT*/ NULL THEN
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
      end

      it "can be an expression with strings and comments embedded" do
        node, rest = parse_some(:expressionUntilThen, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */ THEN
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an expression with strings embedded" do
        node, rest = parse_some(:expressionUntilThen, <<-SQL)
          SELECT id, created_at
          FROM "dataset"
          WHERE value IS NOT NULL
            AND value <> ' THEN this should not terminate expression'
            AND created_at = '2001-01-01' THEN
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 2
      end

      it "should combine trailing whitespace into 'tail' node" do
        node, rest = parse_some(:expressionUntilThen, "a := x + y  \tTHEN")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == "  \t"
      end

      it "should combine trailing comments into 'tail' node" do
        node, rest = parse_some(:expressionUntilThen, "a := x + y /* note -- comment */THEN")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == ' /* note -- comment */'

        node, rest = parse_some(:expressionUntilThen, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */THEN
        SQL
        node.tail.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 2
      end
    end

    describe "expressionUntilLoop" do
      it "does not consume LOOP token" do
        # parser stops in front of LOOP and dies
        lambda{ parse(:expressionUntilLoop, 'abc LOOP') }.should raise_error

        node, rest = parse_some(:expressionUntilLoop, 'abc LOOP xyz')
        rest.should == 'LOOP xyz'
      end

      it "cannot be a blank expression" do
        lambda{ parse_some(:expressionUntilLoop, ' LOOP') }.should raise_error
      end

      it "cannot be a comment" do
        lambda{ parse_some(:expressionUntilLoop, "/* comment */ LOOP") }.should raise_error
        lambda{ parse_some(:expressionUntilLoop, "-- comment\n LOOP") }.should raise_error
      end

      it "can be a string" do
        node, rest = parse_some(:expressionUntilLoop, "'string' LOOP")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1

        node, rest = parse_some(:expressionUntilLoop, "$$ string $$ LOOP")
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an arithmetic expression" do
        node, rest = parse_some(:expressionUntilLoop, "10 * (3 + x) LOOP")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an SQL statement" do
        node, rest = parse_some(:expressionUntilLoop, "SELECT id FROM dataset LOOP")
        node.should be_a(Parser::Nodes::Expression)
      end

      it "can be an expression with comments embedded" do
        node, rest = parse_some(:expressionUntilLoop, <<-SQL)
          SELECT id                    -- primary key  LOOP
          FROM "dataset" /*  LOOP */       -- previous comments shouldn't terminate expression
          WHERE value IS /*NOT*/ NULL LOOP
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
      end

      it "can be an expression with strings and comments embedded" do
        node, rest = parse_some(:expressionUntilLoop, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */ LOOP
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 4
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 1
      end

      it "can be an expression with strings embedded" do
        node, rest = parse_some(:expressionUntilLoop, <<-SQL)
          SELECT id, created_at
          FROM "dataset"
          WHERE value IS NOT NULL
            AND value <> ' LOOP this should not terminate expression'
            AND created_at = '2001-01-01' LOOP
        SQL
        node.should be_a(Parser::Nodes::Expression)
        node.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 2
      end

      it "should combine trailing whitespace into 'tail' node" do
        node, rest = parse_some(:expressionUntilLoop, "a := x + y  \tLOOP")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == "  \t"
      end

      it "should combine trailing comments into 'tail' node" do
        node, rest = parse_some(:expressionUntilLoop, "a := x + y /* note -- comment */LOOP")
        node.should be_a(Parser::Nodes::Expression)
        node.tail.source_text.should == ' /* note -- comment */'

        node, rest = parse_some(:expressionUntilLoop, <<-SQL)
          SELECT id    -- 1. upcoming single quote doesn't matter
          FROM dataset /* 2. this one's no problem either */
          WHERE value LIKE '/* comment within a string! shouldn''t parse a comment */'
            AND length(value) > 10 -- 3. this comment in tail doesn't contain any 'string's
            /* 4. farewell comment in tail */LOOP
        SQL
        node.tail.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 2
      end
    end

  end

end
