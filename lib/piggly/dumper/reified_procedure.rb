module Piggly
  module Dumper

    #
    # Differs from SkeletonProcedure in that the procedure source code is stored
    # as an instance variable.
    #
    class ReifiedProcedure < SkeletonProcedure

      def initialize(source, oid, name, strict, secdef, setof, type, volatility, arg_modes, arg_names, arg_types, arg_defaults)
        @source = source.strip

        if type.name == "record" and type.schema == "pg_catalog" and arg_modes.include?("t")
          prefix       = arg_modes.take_while{|m| m != "t" }.length
          type         = RecordType.new(arg_types[prefix..-1], arg_names[prefix..-1], arg_modes[prefix..-1], arg_defaults[prefix..-1])
          arg_modes    = arg_modes[0, prefix]
          arg_types    = arg_types[0, prefix]
          arg_names    = arg_names[0, prefix]
          arg_defaults = arg_defaults[0, prefix]
          setof        = false
        end

        super(oid, name, strict, secdef, setof, type, volatility, arg_modes, arg_names, arg_types, arg_defaults)
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
                              @volatility, @arg_modes, @arg_names, @arg_types,
                              @arg_defaults)
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
        "b" => "inout",
        "v" => "variadic"

      # Rewrite "i", "v", and "s", otherwise pass-through
      VOLATILITY = Hash.new{|h,k| k }.update \
         "i" => "immutable",
         "v" => "volatile",
         "s" => "stable"

      def mode(mode)
        MODES[mode]
      end

      def volatility(mode)
        VOLATILITY[mode]
      end

      def defaults(exprs, count, total)
        exprs = if exprs.nil? then [] else exprs.split(", ") end

        nreqd = total - count

        if nreqd >= 0 and exprs.length == count
          Array.new(nreqd) + exprs
        else
          raise "Couldn't parse default arguments"
        end
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
            pro.pronargs      as arg_count,
            array_to_string(pro.proargmodes, ',') as arg_modes,
            array_to_string(pro.proargnames, ',') as arg_names,
            case when proallargtypes is not null then
                   -- use proalltypes array if its non-null
                   array_to_string(array(select format_type(proallargtypes[k], null)
                                         from generate_series(array_lower(proallargtypes, 1),
                                                              array_upper(proallargtypes, 1)) as k), ',')
                 else
                   -- fallback to oidvector proargtypes
                   oidvectortypes(pro.proargtypes)
                 end as arg_types,
            pro.pronargdefaults as arg_defaults_count,
            coalesce(pg_get_expr(pro.proargdefaults, 0), '') as arg_defaults
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
            QualifiedName.new(hash["nschema"].to_s, hash["name"].to_s),
            hash["strict"] == "t",
            hash["secdef"] == "t",
            hash["setof"]  == "t",
            QualifiedType.parse(hash["tschema"].to_s, hash["type"].to_s),
            volatility(hash["volatility"]),
            coalesce(hash["arg_modes"].to_s.split(",").map{|x| mode(x.strip) },
                     ["in"]*hash["arg_count"].to_i),
            hash["arg_names"].to_s.split(",").map{|x| QualifiedName.new(nil, x.strip) },
            hash["arg_types"].to_s.split(",").map{|x| QualifiedType.parse(x.strip) },
            defaults(hash["arg_defaults"],
                     hash["arg_defaults_count"].to_i,
                     hash["arg_count"].to_i))
      end

      def coalesce(value, default)
        if [nil, "", []].include?(value)
          default
        else
          value
        end
      end
    end

  end
end
