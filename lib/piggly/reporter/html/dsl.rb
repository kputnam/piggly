module Piggly
  module Reporter
    class Html

      #
      # Markup DSL
      #
      module DSL
        unless defined? HTML_REPLACE
          HTML_REPLACE = { "&" => "&amp;", '"' => "&quot;", ">" => "&gt;", "<" => "&lt;" }
          HTML_PATTERN = /[&"<>]/
        end

        def html(output = "")
          begin
            @htmltag_output, htmltag_output = output, @htmltag_output
            # TODO: doctype
            yield
          ensure
            # restore
            @htmltag_output = htmltag_output
          end
        end

        def tag(name, content = nil, attributes = {})
          if content.is_a?(Hash) and attributes.empty?
            content, attributes = nil, content
          end

          attributes = attributes.inject("") do |string, pair|
            k, v = pair
            string << %[ #{k}="#{v}"]
          end

          if content.nil?
            if block_given?
              @htmltag_output << "<#{name}#{attributes}>"
              yield
              @htmltag_output << "</#{name}>"
            else
              @htmltag_output << "<#{name}#{attributes}/>"
            end
          else
            @htmltag_output << "<#{name}#{attributes}>#{content.to_s}</#{name}>"
          end
        end

        if "".respond_to?(:fast_xs)
          def e(string)
            string.fast_xs
          end
        elsif "".respond_to?(:to_xs)
          def e(string)
            string.to_xs
          end
        else
          def e(string)
            string.gsub(HTML_PATTERN) {|c| HTML_REPLACE[c] }
          end
        end
      end

    end
  end
end
