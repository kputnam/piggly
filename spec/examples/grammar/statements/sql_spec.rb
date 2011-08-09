require 'spec_helper'

module Piggly
  describe Parser, "statements" do
    include GrammarHelper

    describe "SQL statements" do
      it "parse successfully" do
        node, rest = parse_some(:statement, 'SELECT id FROM users;')
        node.should be_a(Parser::Nodes::Statement)
        node.count{|e| e.is_a?(Parser::Nodes::Sql) }.should == 1
        node.find{|e| e.is_a?(Parser::Nodes::Sql) }.source_text.should == 'SELECT id FROM users;'
        rest.should == ''
      end

      it "must end with a semicolon" do
        lambda{ parse(:statement, 'SELECT id FROM users') }.should raise_error
        lambda{ parse_some(:statement, 'SELECT id FROM users') }.should raise_error
      end

      it "can contain comments" do
        node = parse(:statement, <<-SQL.strip)
          SELECT INTO user u.id, /* u.name */, p.fist_name, p.last_name
          FROM users u
          INNER JOIN people p ON p.id = u.person_id
          WHERE u.disabled -- can't login
            AND u.id = 100;
        SQL
        sql = node.find{|e| e.is_a?(Parser::Nodes::Sql) }
        sql.count{|e| e.is_a?(Parser::Nodes::TComment) }.should == 2
      end

      it "can be followed by comments" do
        node, rest = parse_some(:statement, 'SELECT id FROM users; -- comment')
        node.find{|e| e.is_a?(Parser::Nodes::Sql) }.source_text == 'SELECT id FROM users;'
        node.tail.source_text.should == ' -- comment'
        rest.should == ''
      end
      
      it "can be followed by whitespace" do
        node, rest = parse_some(:statement, "SELECT id FROM users;    \n")
        node.find{|e| e.is_a?(Parser::Nodes::Sql) }.source_text == 'SELECT id FROM users;'
        node.tail.source_text.should == "    \n"
        rest.should == ''
      end

      it "can contain strings" do
        node, rest = parse_some(:statement, <<-SQL.strip)
          SELECT INTO user u.id, u.first_name, u.last_name
          FROM users u
          WHERE first_name ILIKE '%a%'
             OR last_name ILIKE '%b%';
        SQL
        sql = node.find{|e| e.is_a?(Parser::Nodes::Sql) }
        sql.count{|e| e.is_a?(Parser::Nodes::TString) }.should == 2
      end

      it "can contain strings and comments" do
        node = parse(:statement, <<-SQL.strip)
          a := (SELECT fk, count(*), 'not a statement;'
                FROM dataset
                WHERE id > 100 /* filter out 'reserved' range */
                  AND id < 900 -- shouldn't be a string
                   OR source_text <> 'alpha /* no comment */;'
                GROUP BY /* pk ; 'abc' */ fk);
        SQL
      end

    end
  end
end
