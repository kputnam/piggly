module Piggly
  module Dumper

    class QualifiedName
      attr_reader :names

      def initialize(name, *names)
        @names = [name, *names].select{|x| x }
      end

      def shorten
        self.class.new(@names.last)
      end

      # @return [String]
      def quote
        @names.map{|name| '"' + name + '"' }.join(".")
      end

      def schema
        @names.first if @names.length > 1
      end

      # @return [String]
      def to_s
        @names.join(".")
      end

      def ==(qn)
        names == qn.names
      end
    end

  end
end
