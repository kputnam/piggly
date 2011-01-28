module Piggly
  module Dumper

    #
    # Encapsulates all the information about a stored procedure, except the
    # procedure's source code is assumed to be on disk and is loaded as needed
    # instead of stored as an instance variable
    #
    class SkeletonProcedure
      attr_accessor :oid, :namespace, :name, :strict, :secdef, :setof, :rettype,
                    :volatility, :arg_modes, :arg_names, :arg_types, :identifier

      def initialize(oid, namespace, name, strict, secdef, setof, rettype, volatility, arg_modes, arg_names, arg_types)
        @oid, @namespace, @name, @strict, @secdef, @rettype, @volatility, @setof, @arg_modes, @arg_names, @arg_types =
          oid, namespace, name, strict, secdef, rettype, volatility, setof, arg_modes, arg_names, arg_types

        @identifier = Digest::MD5.hexdigest(signature)
      end

      # Returns source text for argument list
      def arguments
        @arg_types.zip(@arg_names, @arg_modes).map do |_type, _name, _mode|
          "#{_mode + ' ' if _mode}#{_name + ' ' if _name}#{_type}"
        end.join(', ')
      end

      # Returns source text for return type
      def type
        "#{@setof ? 'setof ' : ''}#{@rettype}"
      end

      # Returns source text for strictness
      def strictness
        @strict ? 'strict' : ''
      end

      # Returns source text for security
      def security
        @secdef ? 'security definer' : ''
      end

      # Returns source SQL function definition statement
      def definition(source)
        [%[create or replace function "#{@namespace}"."#{@name}" (#{arguments})],
         %[ #{strictness} #{security} returns #{type} as $PIGGLY_BODY$],
         source,
         %[$PIGGLY_BODY$ language plpgsql #{@volatility}]].join("\n")
      end

      def signature
        "#{@namespace}.#{@name}(#{@arg_types.join(', ')})"
      end

      def source
        load_source
      end

      def source_path
        Piggly::Config.mkpath(File.join(Piggly::Config.cache_root, 'Dumper'), "#{@identifier}.plpgsql")
      end

      def load_source
        File.read(source_path)
      end

      def purge_source
        puts "Purging cached source for #{@name}"

        FileUtils.rm_r(source_path) if File.exists?(source_path)

        file = Piggly::Compiler::Trace.cache_path(source_path)
        FileUtils.rm_r(file) if File.exists?(file)

        file = Piggly::Reporter.report_path(source_path, '.html')
        FileUtils.rm_r(file) if File.exists?(file)
      end

      def skeleton
        self
      end

      def skeleton?
        true
      end
    end

    #
    # Differs from SkeletonProcedure in that the procedure source code is stored
    # as an instance variable. The store_source method is also added
    #
    class ReifiedProcedure < SkeletonProcedure
      MODES = Hash.new{|h,k| k }.update \
        'i' => 'in',
        'o' => 'out',
        'b' => 'inout'

      VOLATILITY = Hash.new{|h,k| k }.update \
         'i' => 'immutable',
         'v' => 'volatile',
         's' => 'stable'

      class << self
        def fmt_type(type)
          case type
          when /^character varying(.*)/ then "varchar#{$1}"
          when /^character(.*)/         then "char#{$1}"
          when /"char"(.*)/   then "char#{$1}"
          when /^integer(.*)/ then "int#{$1}"
          when /^int4(.*)/    then "int#{$1}"
          when /^int8(.*)/    then "bigint#{$1}"
          when /^float4(.*)/  then "float#{$1}"
          when /^boolean(.*)/ then "bool#{$1}"
          else type
          end
        end

        def fmt_mode(mode)
          MODES[mode]
        end

        def fmt_volatility(mode)
          VOLATILITY[mode]
        end

        # Returns a list of all PL/pgSQL stored procedures in the current database
        def all
          connection.select_all(<<-SQL).map{|x| from_hash(x) }
            select
              pro.oid,
              ns.nspname      as namespace,
              pro.proname     as name,
              pro.proisstrict as strict,
              pro.prosecdef   as secdef,
              pro.provolatile as volatility,
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

        def from_hash(hash)
          new(hash['oid'],
              hash['namespace'],
              hash['name'],
              hash['strict'] == 't',
              hash['secdef'] == 't',
              hash['setof'] == 't',
              fmt_type(hash['rettype']),
              fmt_volatility(hash['volatility']),
              hash['arg_modes'].to_s.split(',').map{|x| fmt_mode(x.strip) },
              hash['arg_names'].to_s.split(',').map{|x| x.strip },
              hash['arg_types'].to_s.split(',').map{|x| fmt_type(x.strip) },
              hash['source'])
        end

      private

        # Returns the current database connection
        def connection # :nodoc:
          ActiveRecord::Base.connection
        end
      end

      attr_reader :source

      def initialize(oid, namespace, name, strict, secdef, setof, rettype, volatility, arg_modes, arg_names, arg_types, source)
        super(oid, namespace, name, strict, secdef, setof, rettype, volatility, arg_modes, arg_names, arg_types)
        @source = source.strip
      end

      def store_source
        if @source.include?('$PIGGLY$')
          raise "Procedure `#{@name}' is already instrumented. " +
                "This means the original source wasn't restored after the " +
                "last coverage run. You must restore the source manually."
        end

        puts "Caching source for #{@name}"

        File.open(source_path, 'wb'){|io| io.write(@source) }
      end

      def skeleton
        SkeletonProcedure.new(oid, namespace, name, strict, secdef, setof,
                              rettype, volatility, arg_modes, arg_names, arg_types)
      end

      def skeleton?
        false
      end
    end

  end
end
