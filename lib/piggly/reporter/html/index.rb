module Piggly
  module Reporter
    class Html
      class Index < Piggly::Reporter::Html
        class << self

          def output(procedures)
            File.open(File.join(report_path, 'index.html'), 'w') do |io|
              html(io) do

                tag :html do
                  tag :head do
                    tag :title, 'Piggly PL/pgSQL Code Coverage'
                    tag :link, :rel => 'stylesheet', :type => 'text/css', :href => 'piggly.css'
                    tag :script, '<!-- -->', :type => 'text/javascript', :src => 'sortable.js'
                  end

                  tag :body do
                    aggregate('PL/pgSQL Coverage Summary', Piggly::Profile.instance.summary)
                    table(procedures.sort_by(&:name))
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
end
