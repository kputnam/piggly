require File.join(File.dirname(__FILE__), 'traversal')

NodeClass = Treetop::Runtime::SyntaxNode

class NodeClass
  include Piggly::Parser::Nodes::Traversal

  # The 'text_value' method can be used to read the parse tree as Treetop
  # originally read it. The 'source_text' method returns redefined value or falls
  # back to original text_value if none was set.

  attr_accessor :source_text

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
        Piggly::Tags::BlockTag.new(prefix, id)
      else
        Piggly::Tags::EvaluationTag.new(prefix, id)
      end.tap{|tag| @tag_id = tag.id }
    end
  end

  def tag_id
    @tag_id or raise RuntimeError, "Node is not tagged"
  end

  def tagged?
    defined? @tag_id
  end

  # overridden in subclasses
  def expression?; false end
  def branch?; false end
  def block?; false end
  def stub?; false end
  def loop?; false end
  def for?; false end
  def while?; false end
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
  module Parser
    module Nodes

      # ...;
      class Statement < NodeClass
        def terminal?
          false
        end
      end

      class Expression < NodeClass
        def expression?
          true
        end

        def tag(prefix = nil, id = nil)
          unless defined? @tag_id
            if named?(:cond)
              if parent.while?
                # this object is the conditional statement in a WHILE loop
                Piggly::Tags::ConditionalLoopTag.new(prefix, id)
              elsif parent.loop?
                # this object is the conditional statement in a loop
                Piggly::Tags::UnconditionalLoopTag.new(prefix, id)
              elsif parent.branch?
                Piggly::Tags::ConditionalBranchTag.new(prefix, id)
              else
                Piggly::Tags::EvaluationTag.new(prefix, id)
              end
            else
              Piggly::Tags::EvaluationTag.new(prefix, id)
            end.tap{|tag| @tag_id = tag.id }
          end
        end

        def terminal?
          false
        end
      end

      # DECLARE declaration BEGIN body END;
      class Block < Statement
        def block?
          true
        end
      end

      # Branches with child 'cond' (Expression) will get a ConditionalBranchTag
      class Branch < Statement
        def branch?
          true
        end
      end

      # IF boolean-cond THEN body
      class If < Branch
        def terminal?
          false
        end
      end

      # ELSE body END
      class Else < NodeClass
        def terminal?
          false
        end
      end

      # EXCEPTION WHEN boolean-cond THEN body
      class Catch < Branch
      end

      # WHEN match-expr THEN body
      class CaseWhen < Branch
      end

      # WHEN boolean-cond THEN body
      class CondWhen < Branch
      end

      # CONTINUE label WHEN boolean-cond;
      class ContinueWhen < Branch
      end

      # EXIT label WHEN boolean-cond;
      class ExitWhen < Branch
      end

      class UnconditionalBranch < Statement
      end

      # RETURN expr
      class Return < UnconditionalBranch
      end

      # EXIT label
      class Exit < UnconditionalBranch
      end

      # CONTINUE label
      class Continue < UnconditionalBranch
      end

      # RAISE EXCEPTION expr
      class Throw < UnconditionalBranch
      end

      # Loops with child 'cond' (Expression/Sql) will get a LoopCondTag
      class Loop < Statement
        def loop?
          true
        end
      end

      # FOR boolean-cond LOOP body END
      class ForLoop < Loop
        def for?
          true
        end
      end

      # WHILE boolean-cond LOOP body END
      class WhileLoop < Loop
        def while?
          true
        end
      end


      # RAISE NOTICE expr
      class Raise < Statement
      end

      # CASE search-expr WHEN ...
      class Case < Statement
      end

      # CASE WHEN ...
      class Cond < Statement
      end

      # lval := rval
      class Assignment < Statement
      end

      # Lval of assignment (rval is an Expression)
      class Assignable < NodeClass
      end

      class Sql < Statement
        def style; 'tQ'; end

        def tag(prefix = nil, id = nil)
          unless defined? @tag_id
            if named?(:cond) and parent.for?
              # this object is the conditional statement in a FOR loop
              Piggly::Tags::UnconditionalLoopTag.new(prefix, id)
            else
              Piggly::Tags::EvaluationTag.new(prefix, id)
            end.tap{|tag| @tag_id = tag.id }
          end
        end
      end

      # Tokens have no children
      class Token < NodeClass
        def initialize(input, interval, elements = nil)
          # prevent children from being assigned
          super(input, interval, nil)
        end

        def terminal?
          true
        end
      end

      # This seems like it should be a Token, but it may contain TComment children
      # that should be highlighted differently than the enclosing whitespace
      class TWhitespace < NodeClass
        def terminal?
          false
        end
      end

      class TKeyword < Token
        def style; 'tK'; end

        def tag(prefix = nil, id = nil)
          unless defined? @tag_id
            if named?(:cond) and parent.loop?
              Piggly::Tags::UnconditionalLoopTag.new(prefix, id)
            else
              Piggly::Tags::EvaluationTag.new(prefix, id)
            end
          end.tap{|tag| @tag_id = tag.id }
        end
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

      # Text nodes have no children
      class TextNode < NodeClass
        def initialize(input, interval, elements = nil)
          # prevent children from being assigned
          super(input, interval, nil)
        end

        def terminal?
          true
        end
      end
      
      # Stub nodes have no children, or content
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
        def parent=(object)
          # this would go in the constructor, but parent is set from outside
          raise Piggly::Parser::Failure, "Grammar does not implement #{object.source_text} at line #{input.line_of(object.interval.first)}"
        end
      end

    end
  end
end
