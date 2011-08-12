require 'spec_helper'

module Piggly

  describe Parser, "control structures" do
    include GrammarHelper

    describe "if statements" do
      describe "if .. then .. end if" do
        it "must end with a semicolon" do
          lambda{ parse(:statement, 'IF cond THEN a := 10; END IF') }.should raise_error
          lambda{ parse_some(:stmtIf, 'IF cond THEN a := 10; END IF') }.should raise_error
        end

        it "parses successfully" do
          node, rest = parse_some(:statement, 'IF cond THEN a := 10; END IF;')
          node.should be_statement
          rest.should == ''
        end

        it "does not have an Else node" do
          node = parse(:statement, 'IF cond THEN a := 10; END IF;')
          node.count{|e| e.else? }.should == 0
          node.count{|e| e.named?(:else) and not e.empty? }.should == 0
        end

        it "has a 'cond' Expression" do
          node = parse(:statement, 'IF cond THEN a := 10; END IF;')
          node.count{|e| e.named?(:cond) }.should == 1
          node.find{|e| e.named?(:cond) }.should be_expression
        end

        it "can have missing body" do
          node = parse(:statement, 'IF cond THEN END IF;')
          node.should be_statement
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.named?(:cond) }.should == 1
        end

        it "can have comment body" do
          node = parse(:statement, 'IF cond THEN /* removed */ END IF;')
          node.should be_statement
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.comment? }.should == 1
          node.find{|e| e.comment? }.source_text.should == '/* removed */'
        end

        it "can have single statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.assignment? }.should == 1
        end

        it "can have multiple statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; b := 10; END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.assignment? }.should == 2
        end

        it "can contain comments" do
          node = parse(:statement, "IF cond /* comment */ THEN -- foo\n  NULL; /* foo */ END IF;")
          node.should be_statement
          node.count{|e| e.comment? }.should == 3
        end
      end

      describe "if .. then .. else .. end if" do
        it "parses successfully" do
          node, rest = parse_some(:statement, 'IF cond THEN a := 10; ELSE a := 20; END IF;')
          node.should be_statement
          rest.should == ''
        end

        it "has an Else node named 'else'" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSE a := 20; END IF;')
          node.count{|e| e.named?(:else) and e.else? }.should == 1
          node.find{|e| e.named?(:else) }.source_text.should == 'ELSE a := 20; '
        end

        it "can have missing else body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSE END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.assignment? }.should == 1
        end

        it "can have comment body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSE /* removed */ END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.comment? }.should == 1
          node.count{|e| e.assignment? }.should == 1
        end

        it "can have single statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSE a := 20; END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.assignment? }.should == 2
        end

        it "can have multiple statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSE a := 20; b := 30; END IF;')
          node.count{|e| e.if? }.should == 1
          node.count{|e| e.assignment? }.should == 3
        end
      end

      describe "if .. then .. elsif .. then .. end if" do
        it "parses successfully" do
          node, rest = parse_some(:statement, 'IF cond THEN a := 10; ELSIF cond THEN a := 20; END IF;')
          node.should be_statement
          rest.should == ''
        end

        it "can have comment body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSIF cond THEN /* removed */ END IF;')
          node.count{|e| e.if? }.should == 2
          node.count{|e| e.comment? }.should == 1
          node.count{|e| e.assignment? }.should == 1
        end

        it "can having missing body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSIF cond THEN END IF;')
          node.count{|e| e.if? }.should == 2
          node.count{|e| e.assignment? }.should == 1
        end

        it "can have single statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSIF cond THEN a := 20; END IF;')
          node.count{|e| e.if? }.should == 2
          node.count{|e| e.assignment? }.should == 2
        end

        it "can have multiple statement body" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSIF cond THEN a := 20; b := 30; END IF;')
          node.count{|e| e.if? }.should == 2
          node.count{|e| e.assignment? }.should == 3
        end

        it "can have many elsif branches" do
          node = parse(:statement, <<-SQL.strip)
            IF cond THEN a := 10;
            ELSIF cond THEN a := 20;
            ELSIF cond THEN a := 30;
            ELSIF cond THEN a := 40;
            ELSIF cond THEN a := 50;
            ELSIF cond THEN a := 60;
            END IF;
          SQL

          node.count{|e| e.named?(:cond) }.should == 6
          node.count{|e| e.if? }.should == 6
          node.count{|e| e.if? and e.named?(:else) }.should == 5
        end

        it "has no Else nodes" do
          node = parse(:statement, 'IF cond THEN a := 10; ELSIF cond THEN a := 20; END IF;')
          node.count{|e| e.else? }.should == 0
        end
      end

      describe "if .. then .. elsif .. then .. else .. endif" do
        before do
          @text = 'IF cond THEN a := 10; ELSIF cond THEN a := 20; ELSE a := 30; END IF;'
        end

        it "parses successfully" do
          node, rest = parse_some(:statement, @text)
          node.should be_statement
          rest.should == ''
        end

        it "has an If node named 'else'" do
          node = parse(:statement, @text)
          node.count{|e| e.named?(:else) and e.if? }.should == 1
          node.find{|e| e.named?(:else) and e.if? }.source_text.should == 'ELSIF cond THEN a := 20; ELSE a := 30; '
        end

        it "has an Else node named 'else'" do
          node = parse(:statement, @text)
          node.count{|e| e.named?(:else) and e.else? }.should == 1
          node.find{|e| e.named?(:else) and e.else? }.source_text.should == 'ELSE a := 30; '
        end

        it "has two If nodes" do
          node = parse(:statement, @text)
          node.count{|e| e.if? }.should == 2
        end
      end
    end

  end
end
