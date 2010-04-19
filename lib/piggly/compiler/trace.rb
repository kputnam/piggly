module Piggly

  #
  # Walks the parse tree, attaching Tag values and rewriting source code to ping them.
  #
  class TraceCompiler
    include FileCache
    include CompilerCache

    attr_accessor :nodes

    def self.compile(tree, args)
      new(args.fetch(:path)).send(:compile, tree)
    end

    def self.compiler_path
      __FILE__
    end

    def initialize(path)
      # create unique prefix for each file, prepended to each node's tag
      @prefix = File.expand_path(path)
      @tags   = []
    end

    #
    # Destructively modifies +tree+ (by attaching tags) and returns the tree
    # along with the modified source code, and the list of tags. The tag list
    # is passed along to Profile to compute coverage information. The tree is
    # passed to PrettyCompiler
    #
    def compile(tree)
      puts "Compiling #{@prefix}"
      return 'code.sql' => traverse(tree),
             'tree'     => tree,
             'tags'     => @tags,
             'prefix'   => @prefix
    end

    def traverse(node)
      if node.terminal? or node.expression?
        node.source_text
      else
        if node.respond_to?(:condStub) and node.respond_to?(:cond)
          # preserve opening parenthesis and whitespace before injecting code. this way 
          # IF(test) becomes IF(piggly_cond(TAG, test)) instead of IFpiggly_cond(TAG, (test))
          pre, cond = node.cond.expr.text_value.match(/\A(\(?[\t\n\r ]*)(.+)\z/m).captures
          node.cond.source_text = ""
          
          @tags << node.cond.tag(@prefix)

          node.condStub.source_text  = "#{pre}piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, #{cond})"
          node.condStub.source_text << traverse(node.cond.tail) # preserve trailing whitespace
        end

        if node.respond_to?(:bodyStub)
          if node.respond_to?(:exitStub) and node.respond_to?(:cond)
            @tags << node.body.tag(@prefix)
            @tags << node.cond.tag(@prefix)

            # a hack to simulate a loop conditional statement in ForLoop. signal condition was true
            # when body is executed. when exit stub is reached, signal condition was false
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
            #   LOOP ... END;
            #   ... ELSE ... END;
            #   CONTINUE label;
            #   EXIT label;
            @tags << node.body.tag(@prefix)
            node.bodyStub.source_text = "perform piggly_branch($PIGGLY$#{node.body.tag_id}$PIGGLY$);#{node.indent(:bodySpace)}"
          end
        end

        # traverse children (in which we just injected code)
        node.elements.map{|e| traverse(e) }.join
      end
    end
  end
end
