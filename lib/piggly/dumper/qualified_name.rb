module Piggly
  module Dumper

    class QualifiedName
      attr_reader :names

      def initialize(name, *names)
        @names = [name, *names].select{|x| x }
      end

      def shorten
        self.class.new(*@names.slice(1..-1))
      end

      # @return [String]
      def quote
        if @names.first == "pg_catalog"
          shorten.quote
        else
          @names.map{|name| quote_id(name) }.join(".")
        end
      end

      def schema
        @names.first if @names.length > 1
      end

      # @return [String]
      def to_s
        if schema == "pg_catalog"
          @names.slice(1..-1).join(".")
        else
          @names.join(".")
        end
      end

      def ==(qn)
        names == qn.names
      end

    protected

      def quote_id(name)
        (name =~ /^[a-z0-9_]+$/) ? name : '"' + name + '"'
      end
    end

  end
end
