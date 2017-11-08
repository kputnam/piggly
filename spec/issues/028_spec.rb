require "spec_helper"

module Piggly
  describe "github issue #28" do
    include GrammarHelper

    it "can parse a GET STACKED DIAGNOSTICS statement" do
      body = 'GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT, text_var2 = PG_EXCEPTION_DETAIL, text_var3 = PG_EXCEPTION_HINT;'

      node = parse(:statement, body)
      node.should be_statement
    end

    it "can parse a procedure with GET STACKED DIAGNOSTICS" do
      body = <<-SQL
      DECLARE
        text_var1 text;
        text_var2 text;
        text_var3 text;
      BEGIN
        RETURN 1/0;
      EXCEPTION WHEN SQLSTATE '22012' THEN
        GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = PG_EXCEPTION_HINT;
      END
      SQL

      node = parse(:start, body.strip)
      node.count{|e| e.branch? }.should == 1 # catch
      node.find{|e| e.branch? }.body.source_text.strip.should =~ /^GET.+HINT;/m
    end

    it "can parse WITH <> AS <> SELECT <> SQL query" do
      body = <<-SQL
      DECLARE
      BEGIN
        WITH n AS (SELECT first_name FROM users where id > 1000)
          SELECT * FROM people WHERE people.first_name = n.first_name;
        RETURN 1;
      END
      SQL

      node = parse(:start, body.strip.downcase)
      node.count{|e| e.sql? }.should == 1
    end
  end
end
