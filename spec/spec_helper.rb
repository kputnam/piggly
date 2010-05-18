require 'rubygems'
require 'spec'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'piggly'))

#Dir[File.join(File.dirname(__FILE__), 'mocks', '*')].each do |m|
#  require File.expand_path(m)
#end

module Piggly
  module GrammarHelper

    COMMENTS = ["abc defghi", "abc -- abc", "quote's", "a 'str'"]

    SQLWORDS = %w[select insert update delete drop alter
                  commit begin rollback set start vacuum]

    KEYWORDS = %w[as := = alias begin by close constant continue
                  cursor debug declare diagnostics else elsif elseif
                  end exception execute exit fetch for from get if
                  in info insert into is log loop move not notice
                  null open or perform raise rename result_oid return
                  reverse row_count scroll strict then to type warning
                  when while]

    def parse(root, input)
      string = input.downcase
      parser = Parser.parser
      parser.root = root
      parser.consume_all_input = true
      parser.parse(string) or raise Parser::Failure, parser.failure_reason
    ensure
      string.replace input
    end

    def parse_some(root, input)
      string = input.downcase
      parser = Parser.parser
      parser.root = root
      parser.consume_all_input = false
      node = parser.parse(string)
      raise Parser::Failure, parser.failure_reason unless node
      return node, input[parser.index..-1]
    ensure
      string.replace input
    end
  end

  # mock NodeClass
  class N < OpenStruct
    # Constructs a terminal
    def self.terminal(text, hash = {})
      new({:text_value => text,
           :terminal?  => true}.update(hash))
    end

    def self.keyword(text)
      terminal text
    end

    # Create a tSpace node
    def self.space(text = ' ')
      terminal text
    end

    # Constructs an inline tComment
    def self.in_comment(text)
      terminal("/* #{text} */",
               :content  => text,
               :elements => ['/*', " #{text} ", '*/'])
    end

    # Constructs a rest-of-the-line comment
    def self.line_comment(text)
      terminal("-- #{text}\n",
               :content  => text,
               :elements => ['--', " #{text}", "\n"])
    end

    # Constructs a stubNode
    def self.stub
      terminal ''
    end

    # Constructs an expressionUntil-type node
    def self.expr(code)
      Node.new :head => ' ',
               :expr => code,
               :tail => ' ',
               :elements => [:head, :expr, :tail]
    end

    # Constructs a sequence (of statements usually)
    def self.sequence(*elements)
      Node.new :elements  => elements
    end

    # Constructs BEGIN/END block or ELSE block
    def self.block(declare, statements)
      Node.new :bodySpace => ' ',
               :bodyStub  => stub,
               :body      => sequence(*statements),
               :elements  => [keyword('begin'), :bodySpace, :bodyStub, :body, keyword('end'), terminal(';')]
    end
    
    # Construct a CASE with a match expression
    def self.case(expression, *whens)
      Node.new :expr     => expr(expression),
               :cases    => whens,
               :elements => [keyword('case'), space, :expr, :cases, keyword('end'), space, keyword('case'), terminal(';')]
    end

    # Construct a CASE with no match expression
    def self.cond(*whens)
      Node.new :cases    => whens,
               :elements => [keyword('case'), space, :cases, keyword('end'), space, keyword('case'), terminal(';')]
    end

    # Constructs a WHEN branch for a CASE with a match expression
    def self.casewhen(pattern, *statements)
      Node.new :condSpace => space,
               :cond      => expr(pattern),
               :bodySpace => space,
               :body      => sequence(*statements),
               :elements  => [keyword('when'), :condSpace, :cond, keyword('then'), :bodySpace, :bodyStub, :body]
    end

    # Constructs a WHEN branch for a CASE with no match expression
    def self.condwhen(expression, *statements)
      Node.new :condSpace => space,
               :condStub  => stub,
               :cond      => expr(expression),
               :bodySpace => space,
               :body      => sequence(*statements),
               :elements  => [keyword('when'), :condSpace, :condStub, :cond, keyword('then'), :bodySpace, :bodyStub, :body]
    end

    # Constructs an IF or ELSIF
    def self.if(cond, body, other)
      Node.new :condSpace => nil,
               :condStub  => stub,
               :cond      => expr(cond),
               :bodySpace => ' ',
               :bodyStub  => stub,
               :body      => body,
               :else      => other,
               :elements  => [keyword('if'), :condSpace, :condStub, :cond, keyword('then'), :bodySpace, :body, :else, keyword('end'), space, keyword('if'), terminal(';')]
    end

    # Constructs an unconditional LOOP
    def self.loop(*statements)
      Node.new :bodySpace => space,
               :bodyStub  => stub,
               :body      => sequence(*statements),
               :doneStub  => stub,
               :elements  => [keyword('loop'), :bodySpace, :bodyStub, :body, :doneStub, keyword('end'), space, keyword('loop'), terminal(';'), :exitStub]
    end

    # Constructs a WHILE loop
    def self.while(condition, *statements)
      Node.new :condSpace => space,
               :condStub  => stub,
               :cond      => expr(condition),
               :bodySpace => space,
               :bodyStub  => stub,
               :body      => sequence(*statements),
               :exitStub  => stub,
               :elements  => [keyword('while'), :condSpace, :condStub, :cond, keyword('loop'), :bodySpace, :bodyStub, :body, keyword('end'), space, keyword('loop'), terminal(';')]
    end

    # Constructs a FOR loop
    def self.for(idents, iterator, *statements)
      Node.new :condSpace => space,
               :cond      => expr(iterator),
               :bodySpace => space,
               :bodyStub  => stub,
               :body      => sequence(*statements),
               :doneStub  => stub,
               :exitStub  => stub,
               :elements  => [keyword('for'), space, idents, keyword('in'), :condSpace, :cond, keyword('loop'), :bodySpace, :bodyStub, :body, :doneStub, keyword('end'), space, keyword('loop'), terminal(';'), :exitStub]
    end

    # Constructs an EXIT statement
    def self.exit(condition = nil)
      if condition
        Node.new :body      => keyword('exit'),
                 :condSpace => space,
                 :condStub  => stub,
                 :cond      => expr(condition),
                 :elements  => [:body, space, keyword('when'), :condSpace, :condStub, :cond, terminal(';')]
      else
        node.new :bodyStub  => stub,
                 :body      => keyword('exit'),
                 :elements  => [:bodyStub, :body, ';']
      end
    end

    # Constructs a CONTINUE statement
    def self.continue(condition = nil)
      if condition
        Node.new :body      => keyword('continue'),
                 :condSpace => space,
                 :condStub  => stub,
                 :cond      => expr(condition),
                 :elements  => [:body, space, keyword('when'), :condSpace, :condStub, :cond, terminal(';')]
      else
        node.new :bodyStub  => stub,
                 :body      => keyword('exit'),
                 :elements  => [:bodyStub, :body, ';']
      end
    end

    # Constructs a RETURN statement
    def self.return(value)
      Node.new :bodyStub => stubNode,
               :body     => sequence(keyword('return'), expr(value)),
               :elements => [:bodyStub, :body]
    end

    # Constructs a RAISE statement
    def self.raise(level, message)
      if level == 'exception'
        Node.new :bodyStub => stubNode,
                 :body     => sequence(keyword('raise'), space, keyword('exception'), space, expr(message), terminal(';')),
                 :elements => [:bodyStub, :body]
      else
        Node.new :elements => [keyword('raise'), space, keyword(level), space, expr(message), terminal(';')]
      end
    end

    class Node < N
      def initialize(hash)
        if elements = hash[:elements]
          elements.map!{|e| e.is_a?(Symbol) ? hash.fetch(e) : e }
        end

        super(hash)
      end

      def text_value
        @text_value ||= elements.inject('') do |string, e|
          string << e.text_value
        end
      end
    end

    def initialize(hash)
      super({:parent      => nil,
             :terminal?   => false,
             :expression? => false,
             :branch?     => false,
             :block?      => false,
             :stub?       => false,
             :loop?       => false,
             :for?        => false,
             :while?      => false,
             :style       => nil,
             :sourceText  => nil }.update(hash))

      elements.each{|c| c.parent = self } if elements
    end

    # Recursively compute the byte-offsets within the source text
    def interval(start=0)
      @start ||= start
      @stop  ||= if terminal?
                   @start + text_value.size
                 else
                   # recursively compute intervals
                   elements.inject(@start) do |prev, e|
                     e.interval(prev).end
                   end
                 end
      @start...@stop
    end

    def source_text
      @source_text || text_value
    end

    def tap
      yield self
      self
    end
  end
end

module Enumerable
  def test_each
    each do |o|
      begin
        yield o
      rescue
        $!.message << "; while evaluating #{o}"
        raise
      end
    end
  end
end
