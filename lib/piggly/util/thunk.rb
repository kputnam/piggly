module Piggly
  module Util
    class Thunk < BlankSlate
      def initialize(&block)
        @block  = block
        @called = false
      end

      def method_missing(name, *args, &block)
        unless @called
          @value = @block.call
        end

        @value.send(name, *args, &block)
      end
    end
  end
end
