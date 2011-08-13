require "spec_helper"

module Piggly
  describe "github issue #18" do
    include GrammarHelper

      it "can parse the example" do
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
