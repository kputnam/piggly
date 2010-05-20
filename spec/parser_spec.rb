require 'spec_helper'

module Piggly

describe Parser do
  
  describe "parse" do
    it "returns a thunk" do
      tree = nil

      lambda do
        tree = Parser.parse('input')
      end.should_not raise_error

      tree.thunk?.should be_true
    end

    context "when the thunk is evaluated" do
      before do
        @parser = mock('PigglyParser')
        Parser.stub(:parser).and_return(@parser)
      end

      it "downcases input string before parsing" do
        input = 'SOURCE CODE'

        @parser.stub(:failure_reason)
        @parser.should_receive(:parse).
          with(input.downcase)

        begin
          Parser.parse(input).force!
        rescue Parser::Failure
          # don't care
        end
      end

      context "when parser fails" do
        it "raises Parser::Failure" do
          input  = 'SOURCE CODE'
          reason = 'expecting someone else'

          @parser.should_receive(:parse).
            and_return(nil)
          @parser.should_receive(:failure_reason).
            and_return(reason)

          lambda do
            Parser.parse('SOURCE CODE').force!
          end.should raise_error(Parser::Failure, reason)
        end
      end

      context "when parser succeeds" do
        it "returns parser's result" do
          input = 'SOURCE CODE'
          tree  = mock('NodeClass', :message => 'result')

          @parser.should_receive(:parse).
            and_return(tree)

          Parser.parse('SOURCE CODE').message.should == tree.message
        end
      end

    end
  end

  describe "parser" do

    context "when the grammar is older than the generated parser" do
      before do
        File.stub(:stale?).and_return(false)
      end

      it "does not regenerate the parser" do
        Treetop::Compiler::GrammarCompiler.should_not_receive(:new)
      # Parser.should_receive(:require).
      #   with(Parser.parser_path)

        Parser.parser
      end

      it "returns an instance of PigglyParser" do
        Parser.parser.should be_a(PigglyParser)
      end
    end

    context "when the generated parser is older than the grammar" do
      before do
        File.stub(:stale?).and_return(true)
      end

      it "regenerates the parser and loads it" do
        compiler = mock('GrammarCompiler')
        compiler.should_receive(:compile).
          with(Parser.grammar_path, Parser.parser_path)

        Treetop::Compiler::GrammarCompiler.should_receive(:new).
          and_return(compiler)

        Parser.should_receive(:load).
          with(Parser.parser_path)

        Parser.parser
      end

      it "returns an instance of PigglyParser" do
        Parser.parser.should be_a(PigglyParser)
      end
    end
  end
end

end
