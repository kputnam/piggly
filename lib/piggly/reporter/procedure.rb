module Piggly
  module Reporter

    class Procedure < Base

      def initialize(config, profile)
        @config, @profile = config, profile
      end

      def report(procedure)
        io = File.open(report_path(procedure.source_path(@config), ".html"), "w")

        begin
          compiler = Compiler::CoverageReport.new(@config)
          data     = compiler.compile(procedure, @profile)

          html(io) do
            tag :html, :xmlns => "http://www.w3.org/1999/xhtml" do
              tag :head do
                tag :title, "Code Coverage: #{procedure.name}"
                tag :link, :rel => "stylesheet", :type => "text/css", :href => "piggly.css"
              end

              tag :body do
                aggregate(procedure.name, @profile.summary(procedure))

                tag :div, :class => "listing" do
                  tag :table do
                    tag :tr do
                      tag :td, "&nbsp;", :class => "signature"
                      tag :td, signature(procedure), :class => "signature"
                    end

                    tag :tr do
                      tag :td, data[:lines].to_a.map{|n| %[<a href="#L#{n}" id="L#{n}">#{n}</a>] }.join("\n"), :class => "lines"
                      tag :td, data[:html], :class => "code"
                    end
                  end
                end

                toc(@profile[procedure])

                timestamp
              end
            end
          end
        ensure
          io.close
        end
      end

    private

      def signature(procedure)
        string = "<span class='tK'>CREATE FUNCTION</span> <b><span class='tI'>#{procedure.name}</span></b>"

        if procedure.arg_names.size <= 1
          string   << " ( "
          separator = ", "
          spacer    = " "
        else
          string   << "\n\t( "
          separator = ",\n\t  "
          spacer    = "\t"
        end

        arguments = procedure.arg_types.zip(procedure.arg_modes, procedure.arg_names).map do |atype, amode, aname|
          amode &&= "<span class='tK'>#{amode.upcase}</span>#{spacer}"
          aname &&= "<span class='tI'>#{aname}</span>#{spacer}"
          "#{amode}#{aname}<span class='tD'>#{atype}</span>"
        end.join(separator)

        string << arguments << " )"
        string << "\n<span class='tK'>RETURNS#{procedure.setof ? ' SETOF' : ''}</span>"
        string << " <span class='tD'>#{procedure.type.shorten}</span>"
        string << "\n  <span class='tK'>SECURITY DEFINER</span>" if procedure.secdef
        string << "\n  <span class='tK'>STRICT</span>" if procedure.strict
        string << "\n  <span class='tK'>#{procedure.volatility.upcase}</span>"

        string
      end

      def toc(tags)
        todo = tags.reject{|t| t.complete? }
        
        tag :div, :class => 'toc' do
          tag :a, 'Index', :href => 'index.html'

          unless todo.empty?
            tag :ol do
              todo.each do |t|
                tag(:li, :class => t.type) { tag :a, t.description, :href => "#T#{t.id}" }
              end
            end
          end
        end
      end
    end

  end
end
