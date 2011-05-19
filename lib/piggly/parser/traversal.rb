module Piggly
  module Parser

    #
    # Routines for traversing a tree; assumes base class defines elements
    # as a method that returns a list of child nodes
    #
    module Traversal
      def inject(init) # :yields: NodeClass => init
        if elements
          elements.inject(yield(init, self)) do |state, e|
            e.inject(state){|succ, n| yield(succ, n) }
          end
        else
          yield(init, self)
        end
      end

      def count # :yields: NodeClass => boolean
        inject(0){|sum, e| yield(e) ? sum + 1 : sum }
      end

      def find # :yields: NodeClass => boolean
        found = false
        catch :done do
          inject(nil) do |_,e|
            if yield(e)
              found = e
              throw :done
            end
          end
        end
        found
      end

      def select # :yields: NodeClass => boolean
        inject([]){|list,e| yield(e) ? list << e : list }
      end

      def flatten # :yields: NodeClass
        if block_given?
          inject([]){|list,e| list << yield(e) }
        else
          inject([]){|list,e| list << e }
        end
      end
    end

  end
end
