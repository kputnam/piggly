
module Piggly
  class Parser
    include FileCache

    class Failure < RuntimeError; end

    # returns parse tree
    def self.parse(string)
      p = parser

      begin
        # lowercase input for case-insensitive parsing,
        # then restore original string after parsing
        input = string.downcase
        tree = p.parse(input)
        tree or raise Failure, "#{p.failure_reason}"
      rescue Failure
        $!.backtrace.clear
        raise
      ensure
        input.replace string
      end
    end

    def self.parser_path;  File.join(File.dirname(__FILE__), 'parser', 'parser.rb')  end
    def self.grammar_path; File.join(File.dirname(__FILE__), 'parser', 'grammar.tt') end
    def self.nodes_path;   File.join(File.dirname(__FILE__), 'parser', 'nodes.rb')   end

    def self.stale?(source)
      File.stale?(cache_path(source), source, grammar_path, parser_path, nodes_path)
    end

    def self.cache(source)
      cache = cache_path(source)

      if stale?(source)
        tree = parse(File.read(source))
        File.open(cache, 'w+') do |f|
          Marshal.dump(tree, f)
          tree
        end
      else
        # ensure parser libraries are loaded
        _ = parser
        Marshal.load(File.read(cache))
      end
    end

    # generate parser as needed
    def self.parser
      require 'treetop'
      require 'piggly/parser/treetop_ruby19_patch'
      require nodes_path

      if File.stale?(parser_path, grammar_path)
        Treetop::Compiler::GrammarCompiler.new.compile(grammar_path, parser_path)
      end

      require parser_path
      ::PigglyParser.new
    end

  end
end
