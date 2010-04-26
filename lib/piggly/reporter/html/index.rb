module Piggly
  module Reporter
    class HtmlIndex < Reporter::Html
      extend HtmlDSL

      class << self
        def output(sources)
          File.open(File.join(report_path, 'index.html'), 'w') do |f|
            html(f) do

              tag :html do
                tag :head do
                  tag :title, 'Piggly PL/pgSQL Code Coverage'
                  tag :link, :rel => 'stylesheet', :type => 'text/css', :href => 'piggly.css'
                  tag :script, '<!-- -->', :type => 'text/javascript', :src => 'sortable.js'
                end

                tag :body do
                  table(*sources.sort)
                  tag :br
                  timestamp
                end
              end

            end
          end
        end
      end

    end
  end
end
