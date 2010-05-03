module Piggly
  module Compiler

    #
    # Walks the parse tree, attaching Tag values and rewriting source code to ping them.
    #
    class Trace
      include Compiler::Cacheable

      # Destructively modifies +tree+ (by attaching tags) and returns the tree
      # along with the modified source code, and the list of tags. The source
      # code is sent to the database. The tag list is used by Profile to compute
      # coverage information. The tree is used in Compiler::Report
      def self.compile(tree, oid)
        new.send(:compile, tree, oid)
      end

    protected

      def compile(tree, oid) # :nodoc:
        @tags = []
        @oid  = oid

        if tree.respond_to?(:thunk?) and tree.thunk?
          tree = tree.force!
        end

        return :code => traverse(tree),
               :tree => tree,
               :tags => @tags
      end

      def traverse(node) # :nodoc:
        if node.terminal? or node.expression?
          node.source_text
        else
          if node.respond_to?(:condStub) and node.respond_to?(:cond)
            # preserve opening parenthesis and whitespace before injecting code. this way 
            # IF(test) becomes IF(piggly_cond(TAG, test)) instead of IFpiggly_cond(TAG, (test))
            pre, cond = node.cond.expr.text_value.match(/\A(\(?[\t\n\r ]*)(.+)\z/m).captures
            node.cond.source_text = ""
            
            @tags << node.cond.tag(@oid)

            node.condStub.source_text  = "#{pre}piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, #{cond})"
            node.condStub.source_text << traverse(node.cond.tail) # preserve trailing whitespace
          end

          if node.respond_to?(:bodyStub)
            if node.respond_to?(:exitStub) and node.respond_to?(:cond)
              @tags << node.body.tag(@oid)
              @tags << node.cond.tag(@oid)

              # a hack to simulate a loop conditional statement in stmtForLoop and stmtLoop.
              # signal condition is true when body is executed, and false when exit stub is reached
              node.bodyStub.source_text  = "perform piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, true);#{node.indent(:bodySpace)}"
              node.bodyStub.source_text << "perform piggly_branch($PIGGLY$#{node.body.tag_id}$PIGGLY$);#{node.indent(:bodySpace)}"

              if node.respond_to?(:doneStub)
                # signal the end of an iteration was reached
                node.doneStub.source_text  = "#{node.indent(:bodySpace)}perform piggly_signal($PIGGLY$#{node.cond.tag_id}$PIGGLY$, $PIGGLY$@$PIGGLY$);"
                node.doneStub.source_text << node.body.indent
              end

              # signal the loop terminated
              node.exitStub.source_text  = "\n#{node.indent}perform piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, false);"
            elsif node.respond_to?(:body)
              # no condition:
              #   BEGIN ... END;
              #   ... ELSE ... END;
              #   CONTINUE label;
              #   EXIT label;
              @tags << node.body.tag(@oid)
              node.bodyStub.source_text = "perform piggly_branch($PIGGLY$#{node.body.tag_id}$PIGGLY$);#{node.indent(:bodySpace)}"
            end
          end

          # traverse children (in which we just injected code)
          node.elements.map{|e| traverse(e) }.join
        end
      end
    end

  end
end
