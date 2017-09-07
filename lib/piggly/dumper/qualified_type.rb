module Piggly
  module Dumper

    class QualifiedType
      attr_reader :schema, :name

      def self.parse(name, rest = nil)
        if rest.to_s == ""
          schema = nil
        else
          schema = name
          name   = rest
        end

        case name
        when /(.*)\[\]$/
          name  = $1
          array = "[]"
        else
          array = ""
        end

        if schema.to_s == ""
          fst, snd = name.split(".", 2)
          if snd.nil?
            new(nil, fst, array)
          else
            new(fst, snd, array)
          end
        else
          new(schema, name, array)
        end
      end

      def initialize(schema, name, array)
        @schema, @name, @array = schema, name, array
      end

      def shorten
        self.class.new(nil, @name, @array)
      end

      def quote
        if @schema
          '"' + @schema + '"."' + @name + '"' + @array
        else
          '"' + @name + '"' + @array
        end
      end

      def to_s
        if @schema and !%w[public pg_catalog].include?(@schema)
          @schema + "." + readable(@name) + @array
        else
          readable(@name) + @array
        end
      end

      def ==(other)
        self.to_s == other.to_s
      end

    protected

      def normalize(name)
        # select format_type(ret.oid, null), ret.typname
        # from pg_type as ret
        # where ret.typname <> format_type(ret.oid, null)
        #   and ret.typname not like '\\_%'
        # group by ret.typname, format_type(ret.oid, null)
        # order by format_type(ret.oid, null);
        case name
        when '"any"'                        then "any"
        when "bigint"                       then "int8"
        when "bit varying"                  then "varbit"
        when "boolean"                      then "bool"
        when '"char"'                       then "char"
        when "character"                    then "bpchar"
        when "character varying"            then "varchar"
        when "double precision"             then "float8"
        when "information_schema\.(.*)"     then $1
        when "integer"                      then "int4"
        when "real"                         then "float4"
        when "smallint"                     then "int2"
        when "timestamp without time zone"  then "timestamp"
        when "timestamp with time zone"     then "timestamptz"
        when "time without time zone"       then "time"
        when "time with time zone"          then "timetz"
        else name
        end
      end

      def readable(name)
        case name
        when /^_(.*)/                 then "#{readable($1)}[]"
        when "bpchar"                 then "char"
        when /^float4(.*)/            then "real#{$1}"
        when /^int2(.*)/              then "smallint#{$1}"
        when /^int4(.*)/              then "int#{$1}"
        when /^int8(.*)/              then "bigint#{$1}"
        when /^serial4(.*)/           then "serial#{$1}"
        else name
        end
      end
    end

  end
end
