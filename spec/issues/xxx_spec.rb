require "spec_helper"

module Piggly
  describe "github issue #TBC" do
    include GrammarHelper

      it "can parse the a GET DIAGNOSTICS expression" do
        body = 'GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT, text_var2 = PG_EXCEPTION_DETAIL, text_var3 = PG_EXCEPTION_HINT;'

        node = parse(:statement, body)
        node.should be_statement
        #node.count{|e| e.comment? }.should == 1
      end

      it "can parse a procedure with GET DIAGNOSTICS" do
        body = <<-SQL
        declare
          text_var1 text;
          text_var2 text;
          text_var3 text;
        begin
          perform 1/0
        exception when others
          get stacked diagnostics text_var1 = MESSAGE_TEXT, text_var2 = PG_EXCEPTION_DETAIL, text_var3 = PG_EXCEPTION_HINT;
        end
        SQL

        node = parse(:start,body)

      end

     it "can parse WHEN <> AS <> SELECT <> SQL query" do
       body = 'WHEN
          n AS (SELECT first_name FROM users WHERE id > 1000)
        SELECT * FROM people WHERE people.first_name = n.first_name;'

       node = parse(:stmtWhenAsSelectSql, body)
       node.count{|e| e.sql? }.should == 1
     end

    it "can parse a procedure with WHEN AS SELECT" do
      body = <<-SQL
        declare
        begin
          WHEN
            n AS (SELECT first_name FROM users WHERE id > 1000)
          SELECT * FROM people WHERE people.first_name = n.first_name;
        end
      SQL

      node = parse(:start,body)
      node.count{|e| e.sql?}.should == 1
    end
  end
end
