module Piggly

  #
  # Pl/pgSQL Parser, returns a tree of NodeClass values (see nodes.rb)
  #
  module Parser

    autoload :Nodes, 'piggly/parser/nodes'

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
        load_support

        if File.stale?(parser_path, grammar_path)
          # regenerate the parser when the grammar is updated
          Treetop::Compiler::GrammarCompiler.new.compile(grammar_path, parser_path)
          load parser_path
        else
          require parser_path
        end

        ::PigglyParser.new
      end
    
    private

      def load_support
        require 'treetop'
        require 'piggly/parser/treetop_ruby19_patch'
        require nodes_path
      end

    end

  end
end
