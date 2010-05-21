module Piggly
  module Parser

    #
    # Routines for traversing a tree; assumes base class defines elements
    # as a method that returns a list of child nodes
    #
    module Traversal
      def fold_down(init) # :yields: NodeClass => init
        if elements
          elements.inject(yield(init, self)) do |state, e|
            e.fold_down(state){|succ, n| yield(succ, n) }
          end
        else
          yield(init, self)
        end
      end

      def count # :yields: NodeClass => boolean
        fold_down(0){|sum, e| yield(e) ? sum + 1 : sum }
      end

      def find # :yields: NodeClass => boolean
        found = false
        catch :done do
          fold_down(nil) do |_,e|
            if yield(e)
              found = e
              throw :done
            end
          end
        end
        found
      end

      def select # :yields: NodeClass => boolean
        fold_down([]){|list,e| yield(e) ? list << e : list }
      end

      def flatten # :yields: NodeClass
        if block_given?
          fold_down([]){|list,e| list << yield(e) }
        else
          fold_down([]){|list,e| list << e }
        end
      end
    end

  end
end
