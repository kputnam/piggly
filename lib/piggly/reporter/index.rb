module Piggly
  module Reporter

    class Index < Base

      def initialize(config, profile)
        @config, @profile = config, profile
      end

      def report(procedures, index)
        io = File.open("#{report_path}/index.html", "w")

        html(io) do
          tag :html do
            tag :head do
              tag :title, "Piggly PL/pgSQL Code Coverage"
              tag :link, :rel => "stylesheet", :type => "text/css", :href => "piggly.css"
              tag :script, "<!-- -->", :type => "text/javascript", :src => "sortable.js"
            end

            tag :body do
              aggregate("PL/pgSQL Coverage Summary", @profile.summary)
              table(procedures.sort_by{|p| index.label(p) }, index)
              timestamp
            end
          end
        end
      ensure
        io.close
      end

    private

      def table(procedures, index)
        tag :table, :class => "summary sortable" do
          tag :tr do
            tag :th, "Procedure"
            tag :th, "Blocks"
            tag :th, "Loops"
            tag :th, "Branches"
            tag :th, "Block Coverage"
            tag :th, "Loop Coverage"
            tag :th, "Branch Coverage"
          end

          procedures.each_with_index do |procedure, k|
            summary = @profile.summary(procedure)
            row     = k.modulo(2) == 0 ? "even" : "odd"
            label   = index.label(procedure)

            tag :tr, :class => row do
              unless summary.include?(:block) or summary.include?(:loop) or summary.include?(:branch)
                # Parser couldn't parse this file
                tag :td, label, :class => "file fail"
                tag(:td, :class => "count") { tag :span, -1, :style => "display:none" }
                tag(:td, :class => "count") { tag :span, -1, :style => "display:none" }
                tag(:td, :class => "count") { tag :span, -1, :style => "display:none" }
                tag(:td, :class => "pct") { tag :span, -1, :style => "display:none" }
                tag(:td, :class => "pct") { tag :span, -1, :style => "display:none" }
                tag(:td, :class => "pct") { tag :span, -1, :style => "display:none" }
              else
                tag(:td, :class => "file") { tag :a, label, :href => procedure.identifier + ".html" }
                tag :td, (summary[:block][:count]  || 0), :class => "count"
                tag :td, (summary[:loop][:count]   || 0), :class => "count"
                tag :td, (summary[:branch][:count] || 0), :class => "count"
                tag(:td, :class => "pct") { percent(summary[:block][:percent])  }
                tag(:td, :class => "pct") { percent(summary[:loop][:percent])   }
                tag(:td, :class => "pct") { percent(summary[:branch][:percent]) }
              end
            end

          end
        end
      end

      def percent(pct)
        if pct
          tag :table, :align => "center" do
            tag :tr do
              tag :td, "%0.2f%%&nbsp;" % pct, :class => "num"

              style =
                case pct.to_f
                when 0...50;  "low"
                when 0...100; "mid"
                else          "high"
                end

              tag :td, :class => "graph" do
                if pct
                  tag :table, :align => "right", :class => "graph #{style}" do
                    tag :tr do
                      tag :td, :class => "covered", :width => (pct/2.0).to_i
                      tag :td, :class => "uncovered", :width => ((100-pct)/2.0).to_i
                    end
                  end
                end
              end
            end
          end
        else
          tag :span, -1, :style => "display:none"
        end
      end
    end

  end
end
