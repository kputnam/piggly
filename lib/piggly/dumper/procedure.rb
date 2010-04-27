module Piggly
  module Dumper
    class Procedure

      class << self
        # Returns a list of all PL/pgSQL stored procedures in the current database
        # TODO: depends on array_agg which is available in PostgreSQL 8.4+
        def all
          connection.select_all(<<-SQL).map{|x| from_hash(x) }
            select
              pro.oid,
              ns.nspname      as namespace,
              pro.proname     as name,
              pro.proisstrict as strict,
              pro.prosecdef   as secdef,
              pro.provolatile as volatile,
              pro.proretset   as setof,
              ret.typname     as type,
              pro.prosrc      as source,
              array_to_string(pro.proargmodes, ', ')  as arg_modes,
              array_to_string(pro.proargnames, ', ')  as arg_names,

              coalesce(
                -- use proalltypes array if its non-null
                (select array_to_string(array_agg(format_type(proallargtypes[k], null)), ', ')
                 from generate_series(array_lower(proallargtypes, 1),
                                      array_upper(proallargtypes, 1)) as k),

                -- fallback to oidvector proargtypes
                oidvectortypes(pro.proargtypes))      as arg_types
            from pg_proc as pro,
                 pg_type as ret,
                 pg_namespace as ns
            where pro.pronamespace = ns.oid
              and pro.proname not like 'piggly_%'
              and pro.prorettype = ret.oid
              and pro.prolang = (select oid from pg_language where lanname = 'plpgsql')
              and pro.pronamespace not in (select oid
                                           from pg_namespace
                                           where nspname like 'pg_%'
                                              or nspname like 'information_schema')
          SQL
        end

        # Instantiates a Procedure
        def from_hash(hash)
          new(hash['oid'],
              hash['namespace'],
              hash['name'],
              hash['strict'] == 't',
              hash['secdef'] == 't',
              hash['setof'] == 't',
              hash['type'],
              hash['volatile'],
              hash['arg_modes'] ? hash['arg_modes'].split(', ') : [],
              hash['arg_names'] ? hash['arg_names'].split(', ') : [],
              hash['arg_types'] ? hash['arg_types'].split(', ') : [],
              hash['source'])
        end

      private

        # Returns the current database connection
        def connection # :nodoc:
          ActiveRecord::Base.connection
        end
      end

      attr_accessor :oid, :namespace, :name, :strict, :secdef, :setof, :type,
                    :volatile, :arg_modes, :arg_names, :arg_types, :source

      def initialize(oid, namespace, name, strict, secdef, setof, type, volatile, arg_modes, arg_names, arg_types, source)
        @oid, @namespace, @name, @strict, @secdef, @type, @volatile, @setof, @arg_modes, @arg_names, @arg_types, @source =
          oid, namespace, name, strict, secdef, type, volatile, setof, arg_modes, arg_names, arg_types, source.strip
      end

      # Returns source text for argument list
      def arguments
        modes = { 'i' => 'in', 'o' => 'out', 'b' => 'inout' }

        arg_names.zip(arg_types, arg_modes).map do |name, type, mode|
          "#{modes.include?(mode) ? modes[mode] + ' ' : ''}#{name} #{type}"
        end.join(', ')
      end

      # Returns source text for volatility
      def volatility
        case volatile
        when 'i'; 'immutable'
        when 'v'; 'volatile'
        when 's'; 'stable'
        end
      end

      # Returns source text for return type
      def type
        "#{setof ? 'setof ' : ''}#{@type}"
      end

      # Returns source text for strictness
      def strictness
        strict ? 'strict' : ''
      end

      # Returns source text for security
      def security
        secdef ? 'security definer' : ''
      end

      # Returns source SQL function definition statement
      def definition(source = @source)
        [%[create or replace function "#{namespace}"."#{name}" (#{arguments})],
         %[ #{strictness} #{security} returns #{type} as $PIGGLY_BODY$],
         source,
         %[$PIGGLY_BODY$ language plpgsql #{volatility}]].join("\n")
      end

      def signature
        "#{type} #{namespace}.#{name}(#{arguments})"
      end

      def source_path
        Piggly::Config.mkpath(File.join(Piggly::Config.cache_root, 'Dumper'), "#{oid}.plpgsql")
      end

      def purge_source
        puts "Purging source for #{name}"
        File.unlink(source_path)
      end

      def store_source
        puts "Storing source for #{name}"
        File.open(source_path, 'wb'){|io| io.write source }
      end

      def ==(other)
        definition == other.definition
      end

    end
  end
end
