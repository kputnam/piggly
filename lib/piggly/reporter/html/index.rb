module Piggly
  module Reporter
    class Html
      class Index < Reporter::Html
        class << self

          def output(procedures, profile)
            io = File.open(File.join(report_path, "index.html"), "w")

            html(io) do
              tag :html do
                tag :head do
                  tag :title, "Piggly PL/pgSQL Code Coverage"
                  tag :link, :rel => "stylesheet", :type => "text/css", :href => "piggly.css"
                  tag :script, "<!-- -->", :type => "text/javascript", :src => "sortable.js"
                end

                tag :body do
                  aggregate("PL/pgSQL Coverage Summary", profile.summary)
                  table(procedures.sort_by{|p| p.name }, profile)
                  timestamp
                end
              end
            end
          ensure
            io.close
          end

        end
      end
    end
  end
end
