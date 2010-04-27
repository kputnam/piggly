module Piggly
  module Compiler

    #
    # Produces HTML output to report coverage of tagged nodes in the tree
    #
    class Report
      include Piggly::Reporter::Html::DSL

      def self.compile(procedure, profile)
        new(profile).send(:compile, procedure)
      end

      def initialize(profile) # :nodoc:
        @profile = profile
      end

    protected

      def compile(procedure) # :nodoc:
        # get (copies of) the tagged nodes from the compiled tree
        data = Piggly::Compiler::Trace.cache(procedure.source_path, procedure.oid)
        html = traverse(data[:tree])

        return :html  => html,
               :lines => 1 .. procedure.definition.count("\n") + 1,
               :tags  => data[:tags]
      end

      def traverse(node, string='') # :nodoc:
        if node.terminal?
          # terminals (leaves) are never tagged
          if node.style
            string << '<span class="' << node.style << '">' << e(node.text_value) << '</span>'
          else
            string << e(node.text_value)
          end
        else
          # non-terminals never write their text_value
          node.elements.each do |child|
            if child.tagged?

              # retreive the profiled tag
              tag = @profile[child.tag_id]

              if tag.complete?
                string << '<span class="' << tag.style << '" id="T' << tag.id << '">'
              else
                string << '<span class="' << tag.style << '" id="T' << tag.id << '" title="' << tag.description << '">'
              end

              traverse(child, string)
              string << '</span>'
            else
              traverse(child, string)
            end
          end
        end

        string
      end

    end
  end
end
