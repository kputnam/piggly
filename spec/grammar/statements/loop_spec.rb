require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

module Piggly
  describe Parser, "control structures" do
    include GrammarHelper

    describe "loops" do
      describe "for loops" do
        it "can loop over integers" do
          node = parse(:stmtForLoop, 'FOR x IN 0 .. 100 LOOP a := x; END LOOP;')
          node.should be_a(Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == '0 .. 100 '
          cond.should be_a(Expression)
        end

        it "can loop over query results" do
          node = parse(:stmtForLoop, 'FOR x IN SELECT * FROM table LOOP a := x; END LOOP;')
          node.should be_a(Statement)

          cond = node.find{|e| e.named?(:cond) }
          cond.source_text.should == 'SELECT * FROM table '
          cond.should be_a(Sql)
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
