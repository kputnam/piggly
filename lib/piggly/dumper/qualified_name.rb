module Piggly
  module Dumper

    class QualifiedName
      attr_reader :names

      def initialize(name, *names)
        @names = [name, *names].select{|x| x }
      end

      # @return [QualifiedName]
      def shorten
        self.class.new(*@names.slice(1..-1))
      end

      # @return [String]
      def schema
        @names.first if @names.length > 1
      end

      # @return [String]
      def quote
        to_a.map{|name| quote_id(name) }.join(".")
      end

      # @return [String]
      def to_s
        to_a.join(".")
      end

      # @return [Array<String>]
      def to_a
        if @names.first == "pg_catalog"
          @names.slice(1..-1)
        else
          @names
        end
      end

      # @return [Boolean]
      def ==(qn)
        names == qn.names
      end

    protected

      def quote_id(id)
        (id =~ /^[a-z0-9\[\]_]+$/) ? id : '"' + id + '"'
      end
    end

  end
end
