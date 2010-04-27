module Piggly

  #
  # Pl/pgSQL Parser, returns a tree of NodeClass values (see nodes.rb)
  #
  module Parser

    class Failure < RuntimeError; end

    class << self
      # Returns lazy parse tree (only parsed when the value is needed)
      def parse(string)
        Piggly::Util::Thunk.new do
          p = parser

          begin
            # downcase input for case-insensitive parsing,
            # then restore original string after parsing
            input = string.downcase
            tree = p.parse(input)
            tree or raise Piggly::Parser::Failure, "#{p.failure_reason}"
          ensure
            input.replace string
          end
        end
      end

      def parser_path;  File.join(File.dirname(__FILE__), 'parser', 'parser.rb')  end
      def grammar_path; File.join(File.dirname(__FILE__), 'parser', 'grammar.tt') end
      def nodes_path;   File.join(File.dirname(__FILE__), 'parser', 'nodes.rb')   end

      # Returns treetop parser (recompiled as needed)
      def parser
        require 'treetop'
        require 'piggly/parser/treetop_ruby19_patch'
        require nodes_path

        if File.stale?(parser_path, grammar_path)
          # regenerate the parser when the grammar is updated
          Treetop::Compiler::GrammarCompiler.new.compile(grammar_path, parser_path)
        end

        load parser_path
        ::PigglyParser.new
      end
    end

  end
end
