module Piggly
  module Dumper
    class Procedure

      class << self
        # Returns a list of all PL/pgSQL stored procedures in the current database
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
              oidvectortypes(pro.proargtypes)         as arg_types
            from pg_proc as pro,
                 pg_type as ret,
                 pg_namespace as ns
            where pro.pronamespace = ns.oid
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
              hash['arg_modes'] ? hash['arg_names'].split(', ') : [],
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
          oid, namespace, name, strict, secdef, type, volatile, setof, arg_modes, arg_names, arg_types, source
      end

      # Returns source text for argument list
      def arguments
        # TODO: modes:
        #   i - IN
        #   o - OUT
        #   b - INOUT
        #   v - VARIADIC
        arg_names.zip(arg_types).map{|x| x.join(' ') }.join(', ')
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
        [%[create or replace "#{namespace}"."#{name}" (#{arguments})],
         %[ #{strictness} #{security} returns #{type} as $PIGGLY_BODY$],
         source,
         %[$PIGGLY_BODY$ language plpgsql #{volatility}]].join("\n")
      end

      def inspect
        "#{type} #{namespace}.#{name} (#{arguments})"
      end

      def source_path
        Piggly::Config.mkpath(File.join(Piggly::Config.cache_root, 'Dumper'), "#{oid}.plpgsql")
      end

      def purge_source
        File.unlink(source_path)
      end

      def store_source
        File.open(source_path, 'wb'){|io| io.write source }
      end

    end
  end
end
