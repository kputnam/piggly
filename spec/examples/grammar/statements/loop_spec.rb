require 'spec_helper'

module Piggly
  describe Parser, "control structures" do
    include GrammarHelper

    describe "loops" do
      describe "for loops" do
        it "can loop over integers" do
          node = parse(:stmtForLoop, 'FOR x IN 0 .. 100 LOOP a := x; END LOOP;')
          node.should be_a(Parser::Nodes::Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == '0 .. 100 '
          cond.should be_a(Parser::Nodes::Expression)
        end

        it "can loop over query results" do
          node = parse(:stmtForLoop, 'FOR x IN SELECT * FROM table LOOP a := x; END LOOP;')
          node.should be_a(Parser::Nodes::Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == 'SELECT * FROM table '
          cond.should be_a(Parser::Nodes::Sql)
        end

        it "can loop over dynamic query results (GH #7)" do
          node = parse(:stmtForLoop, "FOR r IN EXECUTE 'SELECT * FROM pg_user;' LOOP END LOOP;")
          node.should be_a(Parser::Nodes::Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == "EXECUTE 'SELECT * FROM pg_user;' "
          cond.should be_a(Parser::Nodes::Sql)
        end

        it "can loop over dynamic query results when query contains the word 'LOOP' (GH #7)" do
          node = parse(:stmtForLoop, "FOR r IN EXECUTE 'SELECT * FROM pg_user.LOOP;' LOOP END LOOP;")
          node.should be_a(Parser::Nodes::Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == "EXECUTE 'SELECT * FROM pg_user.LOOP;' "
          cond.should be_a(Parser::Nodes::Sql)
        end

        it "GH #18" do
          statement =
            "FOR r IN EXECUTE 'SELECT * FROM ' || quote_ident(schema) || 'pg_user;' LOOP END LOOP;"

          node = parse(:stmtForLoop, statement)
          node.should be_a(Parser::Nodes::Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == "EXECUTE 'SELECT * FROM ' || quote_ident(schema) || 'pg_user;' "
          cond.should be_a(Parser::Nodes::Sql)
        end
      end

      describe "while loops" do
      end

      describe "unconditional loops" do
      end

      describe "continue" do
      end

      describe "break" do
      end
    end
  end
end
