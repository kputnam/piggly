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
              ret.typname     as rettype,
              pro.prosrc      as source,
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
              hash['rettype'],
              hash['volatile'],
              hash['arg_modes'] ? hash['arg_modes'].split(',').map(&:strip) : [],
              hash['arg_names'] ? hash['arg_names'].split(',').map(&:strip) : [],
              hash['arg_types'] ? hash['arg_types'].split(',').map(&:strip) : [],
              hash['source'])
        end

      private

        # Returns the current database connection
        def connection # :nodoc:
          ActiveRecord::Base.connection
        end
      end

      attr_accessor :oid, :namespace, :name, :strict, :secdef, :setof, :rettype,
                    :volatile, :arg_modes, :arg_names, :arg_types, :source, :identified_using

      def initialize(oid, namespace, name, strict, secdef, setof, rettype, volatile, arg_modes, arg_names, arg_types, source)
        @oid, @namespace, @name, @strict, @secdef, @rettype, @volatile, @setof, @arg_modes, @arg_names, @arg_types, @source =
          oid, namespace, name, strict, secdef, rettype, volatile, setof, arg_modes, arg_names, arg_types, source.strip
      end

      # Returns source text for argument list
      def arguments
        modes = { 'i' => 'in', 'o' => 'out', 'b' => 'inout' }

        arg_names.zip(arg_types, arg_modes).map do |aname, atype, amode|
          "#{modes.include?(amode) ? modes[amode] + ' ' : ''}#{aname} #{atype}"
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
        "#{setof ? 'setof ' : ''}#{@rettype}"
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
        "#{type} #{namespace}.#{name}(#{arg_types.join(', ')})"
      end

      def source_path(filename = identifier)
        Piggly::Config.mkpath(File.join(Piggly::Config.cache_root, 'Dumper'), "#{filename}.plpgsql")
      end

      def store_source
        identified_using = Piggly::Config.identify_procedures_using

        if @identified_using and @identified_using != identified_using
          # the file name scheme changed, so remove our old source file
          old = source_path(identifier(@identified_using))
          File.unlink(old) if File.exists?(old)
        end

        puts "Caching source for #{name}"
        @identified_using = identified_using

        File.open(source_path, 'wb'){|io| io.write source }
      end

      def purge_source
        puts "Purging cached source of #{name}"

        if @identified_using
          old = source_path(identifier(@identified_using))
          FileUtils.rm_r(old) if File.exists?(old)

          old = Piggly::Compiler::Trace.cache_path(identifier(@identified_using))
          FileUtils.rm_r(old) if File.exists?(old)

          old = Piggly::Reporter.report_path(identifier(@identified_using), '.html')
          FileUtils.rm_r(old) if File.exists?(old)
        end

        new = source_path
        FileUtils.rm_r(new) if File.exists?(new)

        new = Piggly::Compiler::Trace.cache_path(source_path(identifier))
        FileUtils.rm_r(new) if File.exists?(new)

        new = Piggly::Reporter.report_path(source_path(identifier), '.html')
        FileUtils.rm_r(new) if File.exists?(new)
      end

      def rename(from = identifier(identified_using))
        @identified_using = Piggly::Config.identify_procedures_using
        File.rename(source_path(from), source_path)
        File.rename(Piggly::Compiler::Trace.cache_path(source_path(from)),
                    Piggly::Compiler::Trace.cache_path(source_path))
      end

      def identifier(method = Piggly::Config.identify_procedures_using)
        case method.to_s
        when 'name'
          name
        when 'oid'
          oid
        when 'signature'
          # prevent Errno::ENAMETOOLONG
          Digest::MD5.hexdigest(signature)
        else
          raise "Procedure identifier method #{method.inspect} is not recognized"
        end
      end

      def ==(other)
        definition == other.definition
      end

    end
  end
end
