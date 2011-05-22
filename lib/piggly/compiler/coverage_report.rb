module Piggly
  module Compiler

    #
    # Produces HTML output to report coverage of tagged nodes in the tree
    #
    class CoverageReport
      include Reporter::HtmlDsl

      def initialize(config)
        @config = config
      end

      def compile(procedure, profile)
        trace = Compiler::TraceCompiler.new(@config)

        if trace.stale?(procedure)
          raise StaleCacheError,
            "stale cached syntax tree for #{procedure.name}"
        end

        # Get (copies of) the tagged nodes from the compiled tree
        data = trace.compile(procedure)

        return :html  => traverse(data[:tree], profile),
               :lines => 1 .. procedure.source(@config).count("\n") + 1
      end

    protected

      # @return [String]
      def traverse(node, profile, string = "")
        if node.tagged?
          tag = profile[node.tag_id]

          if tag.complete?
            string << %[<span class="#{tag.style}" id="T#{tag.id}">]
          else
            string << %[<span class="#{tag.style}" id="T#{tag.id}" title="#{tag.description}">]
          end
        end

        if node.terminal?
          if style = node.style
            string << %[<span class="#{style}">#{e(node.text_value)}</span>]
          else
            string << e(node.text_value)
          end
        else
          # Non-terminals never write their text_value
          node.elements.each{|child| traverse(child, profile, string) }
        end

        if node.tagged?
          string << %[</span>]
        end

        string
      end

    end
  end
end
