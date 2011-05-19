module Piggly
  module Compiler

    #
    # Produces HTML output to report coverage of tagged nodes in the tree
    #
    class Report
      include Reporter::Html::DSL

      def self.compile(procedure, profile)
        new(profile).send(:compile, procedure)
      end

      def initialize(profile) # :nodoc:
        @profile = profile
      end

    protected

      def compile(procedure) # :nodoc:
        unless Compiler::Trace.stale?(procedure.source_path)
          # get (copies of) the tagged nodes from the compiled tree
          data = Compiler::Trace.cache(procedure, procedure.oid)

          return :html  => traverse(data[:tree]),
                 :lines => 1 .. procedure.source.count("\n") + 1
        end
      end

      def traverse(node, string='') # :nodoc:
        if node.tagged?
          tag = @profile[node.tag_id]

          if tag.complete?
            string << '<span class="' << tag.style << '" id="T' << tag.id << '">'
          else
            string << '<span class="' << tag.style << '" id="T' << tag.id << '" title="' << tag.description << '">'
          end
        end

        if node.terminal?
          if style = node.style
            string << '<span class="' << style << '">' << e(node.text_value) << '</span>'
          else
            string << e(node.text_value)
          end
        else
          # non-terminals never write their text_value
          node.elements.each{|child| traverse(child, string) }
        end

        if node.tagged?
          string << '</span>'
        end

        string
      end

    end
  end
end
