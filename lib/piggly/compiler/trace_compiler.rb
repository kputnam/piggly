module Piggly
  module Compiler

    #
    # Walks the parse tree, attaching Tag values and rewriting source code to ping them.
    #
    class TraceCompiler
      include Util::Cacheable

      def initialize(config)
        @config = config
      end

      # Is the cache_path is older than its source path or the other files?
      def stale?(procedure)
        Util::File.stale?(cache_path(procedure.source_path(@config)),
                          procedure.source_path(@config),
                          *self.class.cache_sources)
      end

      def compile(procedure)
        cache = CacheDir.new(cache_path(procedure.source_path(@config)))

        if stale?(procedure)
          begin
          $stdout.puts "Compiling #{procedure.name}"
          tree = Parser.parse(IO.read(procedure.source_path(@config)))
          tree = tree.force! if tree.respond_to?(:thunk?)

          tags = []
          code = traverse(tree, procedure.oid, tags)

          cache.replace(:tree => tree, :code => code, :tags => tags)
          rescue RuntimeError => e
            $stdout.puts <<-EXMSG
            ****
            Error compiling procedure #{procedure.name}
            Source: #{procedure.source_path(@config)}
            Exception Message:
            #{e.message}
            ****
            EXMSG
          end

        end

        cache
      end

    protected

      # Rewrites the parse tree to call instrumentation helpers, and destructively
      # updates `tags` by appending the tags of instrumented nodes
      #   @return [String]
      def traverse(node, oid, tags)
        if node.terminal? or node.expression?
          node.source_text
        else
          if node.respond_to?(:condStub) and node.respond_to?(:cond)
            # Preserve opening parenthesis and whitespace before injecting code. This way 
            # IF(test) becomes IF(piggly_cond(TAG, test)) instead of IFpiggly_cond(TAG, (test))
            pre, cond = node.cond.expr.text_value.match(/\A(\(?[\t\n\r ]*)(.+)\z/m).captures
            node.cond.source_text = ""

            tags << node.cond.tag(oid)

            node.condStub.source_text  = "#{pre}public.piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, (#{cond}))"
            node.condStub.source_text << traverse(node.cond.tail, oid, tags) # preserve trailing whitespace
          end

          if node.respond_to?(:bodyStub)
            if node.respond_to?(:exitStub) and node.respond_to?(:cond)
              tags << node.body.tag(oid)
              tags << node.cond.tag(oid)

              # Hack to simulate a loop conditional statement in stmtForLoop and stmtLoop.
              # signal condition is true when body is executed, and false when exit stub is reached
              node.bodyStub.source_text  = "perform public.piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, true);#{node.indent(:bodySpace)}"
              node.bodyStub.source_text << "perform public.piggly_branch($PIGGLY$#{node.body.tag_id}$PIGGLY$);#{node.indent(:bodySpace)}"

              if node.respond_to?(:doneStub)
                # Signal the end of an iteration was reached
                node.doneStub.source_text  = "#{node.indent(:bodySpace)}perform public.piggly_signal($PIGGLY$#{node.cond.tag_id}$PIGGLY$, $PIGGLY$@$PIGGLY$);"
                node.doneStub.source_text << node.body.indent
              end

              # Signal the loop terminated
              node.exitStub.source_text  = "\n#{node.indent}perform public.piggly_cond($PIGGLY$#{node.cond.tag_id}$PIGGLY$, false);"
            elsif node.respond_to?(:body)
              # Unconditional branches (or blocks)
              #   BEGIN ... END;
              #   ... ELSE ... END;
              #   CONTINUE label;
              #   EXIT label;
              tags << node.body.tag(oid)
              node.bodyStub.source_text = "perform public.piggly_branch($PIGGLY$#{node.body.tag_id}$PIGGLY$);#{node.indent(:bodySpace)}"
            end
          end

          # Traverse children (in which we just injected code)
          node.elements.map{|e| traverse(e, oid, tags) }.join
        end
      end
    end

    class << TraceCompiler

      # Each of these files' mtimes are used to determine when another file is stale
      def cache_sources
        [Parser.grammar_path,
         Parser.parser_path,
         Parser.nodes_path]
      end
    end

  end
end
