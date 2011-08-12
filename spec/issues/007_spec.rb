require "spec_helper"

module Piggly
  describe "github issue #7" do
    include GrammarHelper

    it "can loop over dynamic query results" do
      node = parse(:stmtForLoop, "FOR r IN EXECUTE 'SELECT * FROM pg_user;' LOOP END LOOP;")
      node.should be_statement

      cond = node.find{|e| e.named?(:cond) }
      cond.source_text.should == "EXECUTE 'SELECT * FROM pg_user;' "
      cond.should be_sql
    end

    it "can loop over dynamic query results when query contains the word 'LOOP'" do
      node = parse(:stmtForLoop, "FOR r IN EXECUTE 'SELECT * FROM pg_user.LOOP;' LOOP END LOOP;")
      node.should be_statement

      cond = node.find{|e| e.named?(:cond) }
      cond.source_text.should == "EXECUTE 'SELECT * FROM pg_user.LOOP;' "
      cond.should be_sql
    end
  end
end
