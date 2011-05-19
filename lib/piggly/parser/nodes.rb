NodeClass = Treetop::Runtime::SyntaxNode

class NodeClass
  include Piggly::Parser::Traversal

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
        Tags::BlockTag.new(prefix, id)
      else
        Tags::EvaluationTag.new(prefix, id)
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

  # True if node is called `label` by the parent node
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
                # This node is the conditional in a WHILE loop
                Tags::ConditionalLoopTag.new(prefix, id)
              elsif parent.loop?
                # This node is the conditional in a loop
                Tags::UnconditionalLoopTag.new(prefix, id)
              elsif parent.branch?
                # This node is a conditional in a branch
                Tags::ConditionalBranchTag.new(prefix, id)
              else
                Tags::EvaluationTag.new(prefix, id)
              end
            else
              Tags::EvaluationTag.new(prefix, id)
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

      # Loops that have a child named :cond (which should be either an Expression
      # or Sql node) will get a LoopCondTag from the #tag method
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

      class Sql < Expression
        def style; "tQ"; end

        def tag(prefix = nil, id = nil)
          unless defined? @tag_id
            if named?(:cond) and parent.for?
              # This node is the conditional in a FOR loop
              Tags::UnconditionalLoopTag.new(prefix, id)
            else
              Tags::EvaluationTag.new(prefix, id)
            end.tap{|tag| @tag_id = tag.id }
          end
        end
      end

      # Terminals have no children
      class Terminal < NodeClass
        def initialize(input, interval, elements = nil)
          # Third argument nil prevents children from being assigned
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

      class Token < Terminal
      end

      class TKeyword < Token
        def style; "tK"; end

        def tag(prefix = nil, id = nil)
          unless defined? @tag_id
            if named?(:cond) and parent.loop?
              Tags::UnconditionalLoopTag.new(prefix, id)
            else
              Tags::EvaluationTag.new(prefix, id)
            end
          end.tap{|tag| @tag_id = tag.id }
        end
      end

      class TIdentifier < Token
        def style; "tI"; end
      end

      class TDatatype < Token
        def style; "tD"; end
      end

      class TString < Token
        def style; "tS"; end
      end

      class TDollarQuoteMarker < Token
        def style; "tM"; end
      end

      class TComment < Token
        def style; "tC"; end
      end

      class TLabel < Token
        def style; "tL"; end
      end

      class TextNode < Terminal
      end
      
      # Stub nodes have no children, or content
      class StubNode < Terminal
        def stub?
          true
        end
      end

      class NotImplemented < NodeClass
        def parent=(object)
          # this would go in the constructor, but parent is set from outside
          raise Failure, "Grammar does not implement #{object.source_text} at line #{input.line_of(object.interval.first)}"
        end
      end

    end
  end
end
