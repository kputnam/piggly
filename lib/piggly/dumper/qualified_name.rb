module Piggly
  module Dumper

    class QualifiedName
      attr_reader :schema, :name

      def initialize(schema, name)
        @schema, @name = schema, name
      end

      # @return [String]
      def quote
        if @schema
          '"' + @schema + '"."' + @name + '"'
        else
          '"' + @name + '"'
        end
      end

      # @return [String]
      def to_s
        if @schema
          @schema + "." + @name
        else
          @name
        end
      end

      # @return [Boolean]
      def ==(other)
        self.to_s == other.to_s
      end
    end

  end
end
