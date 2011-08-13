module Piggly
  module Dumper

    #
    # Differs from SkeletonProcedure in that the procedure source code is stored
    # as an instance variable.
    #
    class ReifiedProcedure < SkeletonProcedure

      def initialize(source, *args)
        super(*args)
        @source = source.strip
      end

      # @return [String]
      def source(config)
        @source
      end

      # @return [void]
      def store_source(config)
        if @source.include?("$PIGGLY$")
          raise "Procedure `#{@name}' is already instrumented. " +
                "This means the original source wasn't restored after the " +
                "last coverage run. You must restore the source manually."
        end

        File.open(source_path(config), "wb"){|io| io.write(@source) }
      end

      # @return [SkeletonProcedure]
      def skeleton
        SkeletonProcedure.new(@oid, @name, @strict, @secdef, @setof, @type,
                              @volatility, @arg_modes, @arg_names, @arg_types)
      end

      def skeleton?
        false
      end
    end

    class << ReifiedProcedure
      # Rewrite "i", "o", and "b", otherwise pass-through
      MODES = Hash.new{|h,k| k }.update \
        "i" => "in",
        "o" => "out",
        "b" => "inout"

      # Rewrite "i", "v", and "s", otherwise pass-through
      VOLATILITY = Hash.new{|h,k| k }.update \
         "i" => "immutable",
         "v" => "volatile",
         "s" => "stable"

      # Make the system calatog type name more human readable
      # @return [QualifiedName]
      def shorten(name)
        # This drops the schema (not good), but right now the
        # caller doesn't ever provide the schema anyway.
        case name
        when /^character varying(.*)/ then "varchar#{$1}"
        when /^character(.*)/         then "char#{$1}"
        when /"char"(.*)/   then "char#{$1}"
        when /^integer(.*)/ then "int#{$1}"
        when /^int4(.*)/    then "int#{$1}"
        when /^int8(.*)/    then "bigint#{$1}"
        when /^float4(.*)/  then "float#{$1}"
        when /^boolean(.*)/ then "bool#{$1}"
        else name
        end
      end

      def q(name, *names)
        QualifiedName.new(name, *names)
      end

      def mode(mode)
        MODES[mode]
      end

      def volatility(mode)
        VOLATILITY[mode]
      end

      # Returns a list of all PL/pgSQL stored procedures in the current database
      #
      # @return [Array<ReifiedProcedure>]
      def all(connection)
        connection.query(<<-SQL).map{|x| from_hash(x) }
          select
            pro.oid,
            nschema.nspname   as nschema,
            pro.proname       as name,
            pro.proisstrict   as strict,
            pro.prosecdef     as secdef,
            pro.provolatile   as volatility,
            pro.proretset     as setof,
            rschema.nspname   as tschema,
            ret.typname       as type,
            pro.prosrc        as source,
            array_to_string(pro.proargmodes, ',')  as arg_modes,
            array_to_string(pro.proargnames, ',')  as arg_names,

            case
            when proallargtypes is not null then
              -- use proalltypes array if its non-null
              array_to_string(array(select format_type(proallargtypes[k], null)
                                    from generate_series(array_lower(proallargtypes, 1),
                                                         array_upper(proallargtypes, 1)) as k), ',')
            else
              -- fallback to oidvector proargtypes
              oidvectortypes(pro.proargtypes)
            end             as arg_types
          from pg_proc as pro,
               pg_type as ret,
               pg_namespace as nschema,
               pg_namespace as rschema
          where pro.pronamespace = nschema.oid
            and ret.typnamespace = rschema.oid
            and pro.proname not like 'piggly_%'
            and pro.prorettype = ret.oid
            and pro.prolang = (select oid from pg_language where lanname = 'plpgsql')
            and pro.pronamespace not in (select oid
                                         from pg_namespace
                                         where nspname like 'pg_%'
                                            or nspname like 'information_schema')
        SQL
      end

      # Construct a ReifiedProcedure from a result row (Hash)
      #
      # @return [ReifiedProcedure]
      def from_hash(hash)
        new(hash["source"],
            hash["oid"],
            q(hash["nschema"], hash["name"]),
            hash["strict"] == "t",
            hash["secdef"] == "t",
            hash["setof"]  == "t",
            q(hash["tschema"], shorten(hash["type"])),
            volatility(hash["volatility"]),
            hash["arg_modes"].to_s.split(",").map{|x| mode(x.strip) },
            hash["arg_names"].to_s.split(",").map{|x| q(x.strip) },
            hash["arg_types"].to_s.split(",").map{|x| q(shorten(x.strip)) })
      end
    end

  end
end
