require "spec_helper"

module Piggly
  describe "github issue #18" do
    include GrammarHelper

      it "can loop over dynamic query built by || operators" do
        statement =
          "FOR r IN EXECUTE 'SELECT * FROM ' || quote_ident(schema) || 'pg_user;' LOOP END LOOP;"

        node = parse(:statement, statement)
        node.should be_statement

        cond = node.find{|e| e.named?(:cond) }
        cond.source_text.should == "EXECUTE 'SELECT * FROM ' || quote_ident(schema) || 'pg_user;' "
        cond.should be_sql
      end

      it "can parse the full example" do
        body = <<-SQL
          DECLARE
            schema TEXT = 'pg_catalog';
            r RECORD;
          BEGIN
            FOR r IN EXECUTE 'SELECT * FROM ' || quote_ident(schema) || 'pg_user;'
            LOOP
              -- do nothing
            END LOOP;
          END;
        SQL

        node = parse(:start, body)
        node.count{|e| e.for? }.should == 1
        node.count{|e| e.comment? }.should == 1
      end
  end
end
