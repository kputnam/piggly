module Piggly
  module Util

    # @todo: Ruby 1.9 BasicObject
    begin
      BlankSlate
    rescue NameError
      require "piggly/util/blankslate"
    end

    #
    # Wraps a computation and delays its evaluation until
    # a message is sent to it. Computation can be forced by
    # calling `force!`
    #
    class Thunk < BlankSlate
      def initialize(&block)
        @block = block
      end

      def force!
        unless @block.nil?
          @value = @block.call
          @block = nil
        end

        @value
      end

      def thunk?
        true
      end

      def method_missing(name, *args, &block)
        force!.send(name, *args, &block)
      end
    end
  end
end
