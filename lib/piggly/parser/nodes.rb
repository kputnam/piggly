require File.join(File.dirname(__FILE__), 'traversal')

NodeClass = Treetop::Runtime::SyntaxNode

class NodeClass
  include Piggly::NodeTraversal

  # The 'text_value' method can be used to read the parse tree as Treetop
  # originally read it. The 'source_text' method returns redefined value or falls
  # back to original text_value if none was set.

  attr_accessor :source_text

  def value
    puts "NodeClass#value is deprecated: #{caller.first}"
    text_value
  end

  def source_text
    @source_text || text_value
  end

  #
  # Return a newly created Tag value, but only the tag.id is attached to the tree. The
  # reason that is we maintain the Tags in a separate collection (to avoid a full traversal
  # just to get the list of tags later), and we can retrieve the Tag associated with this
  # node by its tag_id.
  #
  def tag(prefix = nil, id = nil)
    unless defined? @tag_id
      if named?(:body)
        Piggly::BlockTag.new(prefix, id)
      else
        Piggly::EvaluationTag.new(prefix, id)
      end.tap{|tag| @tag_id = tag.id }
    end
  end

  def tag_id
    @tag_id or raise RuntimeError, "Node is not tagged"
  end

  def tagged?
    not @tag_id.nil?
  end

  # overridden in subclasses
  def expression?; false end
  def branch?; false end
  def block?; false end
  def stub?; false end
  def loop?; false end
  def for?; false end
  def style; nil end

  def indent(method = nil)
    if method and respond_to?(method)
      send(method).text_value[/\n[\t ]*\z/]
    else
      text_value[/\n[\t ]*\z/]
    end
  end

  alias o_inspect inspect

  def inspect(indent = '')
    if terminal?
        em = extension_modules
        interesting_methods = methods-[em.last ? em.last.methods : nil]-self.class.instance_methods
        im = interesting_methods.size > 0 ? " (#{interesting_methods.join(",")})" : ""
        tv = text_value
        tv = "...#{tv[-20..-1]}" if tv.size > 20

        indent +
        self.class.to_s.sub(/.*:/,'') +
          em.map{|m| "+"+m.to_s.sub(/.*:/,'')}*"" +
          " offset=#{interval.first}" +
          ", #{tv.inspect}" +
          im
    else
      o_inspect(indent)
    end
  end

  # true if node is called 'label' in parent node
  def named?(label)
    if p = parent
      p.respond_to?(label) and p.send(label).equal?(self)
    end
  end
end

module Piggly

  # CREATE OR REPLACE ...
  class Procedure < NodeClass
  end

  class Statement < NodeClass
    # ...;
  end

  class Expression < NodeClass
    def expression?
      true
    end

    def tag(prefix = nil, id = nil)
      unless defined? @tag_id
        if named?(:cond)
          if parent.loop?
            Piggly::LoopConditionTag.new(prefix, id)
          elsif parent.branch?
            Piggly::BranchConditionTag.new(prefix, id)
          end
        else
          Piggly::Evaluation.new(prefix, id)
        end.tap{|tag| @tag_id = tag.id }
      end
    end
  end

  class Block < Statement
    # DECLARE declaration BEGIN body END;
    def block?
      true
    end
  end



  # branches with child 'cond' (Expression) will get a BranchCondTag
  class Branch < Statement
    def branch?
      true
    end
  end

  class If < Branch
    # IF boolean-cond THEN body
  end

  class Else < NodeClass
    # ELSE body END
  end

  class Catch < Branch
    # EXCEPTION WHEN boolean-cond THEN body
  end

  class CaseWhen < Branch
    # WHEN match-expr THEN body
  end

  class CondWhen < Branch
    # WHEN boolean-cond THEN body
  end

  class ContinueWhen < Branch
    # CONTINUE label WHEN boolean-cond;
  end

  class ExitWhen < Branch
    # EXIT label WHEN boolean-cond;
  end



  class UnconditionalBranch < Statement
  end

  # unconditional branches
  class Return < UnconditionalBranch
    # RETURN expr
  end

  class Exit < UnconditionalBranch
    # EXIT label
  end

  class Continue < UnconditionalBranch
    # CONTINUE label
  end

  class Throw < UnconditionalBranch
    # RAISE EXCEPTION expr
  end



  # loops with child 'cond' (Expression/Sql) will get a LoopCondTag
  class Loop < Statement
    def loop?
      true
    end
  end

  class ForLoop < Loop
    # FOR boolean-cond LOOP body END
    def for?
      true
    end
  end

  class WhileLoop < Loop
    # WHILE boolean-cond LOOP body END
  end



  class Raise < Statement
    # RAISE NOTICE expr
  end

  class Case < Statement
    # CASE search-expr WHEN ...
  end

  class Cond < Statement
    # CASE WHEN ...
  end

  class Assignment < Statement
    # lval := rval
  end

  # lval of assignment (rval is an Expression)
  class Assignable < NodeClass
  end

  class Sql < Statement
    def style; 'tQ'; end

    def tag(prefix = nil, id = nil)
      unless defined? @tag_id
        if named?(:cond) and parent.for?
          # this object is the conditional statement in a FOR loop
          Piggly::ForCollectionTag.new(prefix, id)
        else
          Piggly::EvaluationTag.new(prefix, id)
        end.tap{|tag| @tag_id = tag.id }
      end
    end
  end



  # tokens have no children
  class Token < NodeClass
    def initialize(input, interval, elements = nil)
      # prevent children from being assigned
      super(input, interval, nil)
    end

    def terminal?
      true
    end
  end

  class TWhitespace < NodeClass
    # this seems like it should be a Token but it may contain TComment children
  end

  class TKeyword < Token
    def style; 'tK'; end
  end

  class TIdentifier < Token
    def style; 'tI'; end
  end

  class TDatatype < Token
    def style; 'tD'; end
  end

  class TString < Token
    def style; 'tS'; end
  end

  class TDollarQuoteMarker < Token
    def style; 'tM'; end
  end

  class TComment < Token
    def style; 'tC'; end
  end

  class TLabel < Token
    def style; 'tL'; end
  end



  # text nodes have no children
  class TextNode < NodeClass
    def initialize(input, interval, elements = nil)
      # prevent children from being assigned
      super(input, interval, nil)
    end

    def terminal?
      true
    end
  end
  
  class StubNode < NodeClass
    def initialize(input, interval, elements = nil)
      # prevent children from being assigned
      super(input, interval, nil)
    end

    def terminal?
      true
    end

    def stub?
      true
    end
  end

  class NotImplemented < NodeClass
    # this would go in the constructor, but parent is set from outside
    def parent=(object)
      raise Piggly::Parser::Failure, "Grammar does not implement #{object.source_text} at line #{input.line_of(object.interval.first)}"
    end
  end
end
