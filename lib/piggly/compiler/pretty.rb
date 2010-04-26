require File.join(File.dirname(__FILE__), *%w(.. reporter))

module Piggly

  #
  # Produces HTML output to report coverage of tagged nodes in the tree
  #
  class PrettyCompiler
    include HtmlTag

    def self.compile(path, profile)
      new(profile).send(:compile, path)
    end

    def initialize(profile)
      @profile = profile
    end

  private

    def compile(path)
      lines = File.read(path).count("\n") + 1

      # recompile (should be cache hit) to identify tagged nodes
      data = TraceCompiler.cache(path)
      html = traverse(data['tree'])

      return 'html'  => html,
             'lines' => 1..lines,
             'tags'  => data['tags']
    end

    def traverse(node, string='')
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
            tag = @profile.by_id[child.tag_id]

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
