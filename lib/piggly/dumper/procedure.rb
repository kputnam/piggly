module Piggly
  module Dumper

    #
    # Encapsulates all the information about a stored procedure, except the
    # procedure's source code, which is assumed to be on disk, loaded as needed.
    #
    class SkeletonProcedure

      attr_reader :oid, :name, :type, :arg_types, :arg_modes, :arg_names,
        :strict, :type, :setof, :volatility, :secdef, :identifier

      def initialize(oid, name, strict, secdef, setof, type, volatility, arg_modes, arg_names, arg_types)
        @oid, @name, @strict, @secdef, @type, @volatility, @setof, @arg_modes, @arg_names, @arg_types =
          oid, name, strict, secdef, type, volatility, setof, arg_modes, arg_names, arg_types

        @identifier = Digest::MD5.hexdigest(signature)
      end

      # Returns source text for argument list
      # @return [String]
      def arguments
        @arg_types.zip(@arg_names, @arg_modes).map do |type, name, mode|
          "#{mode + " " if mode}#{name.quote + " " if name}#{type.shorten}"
        end.join(", ")
      end

      # Returns source text for return type
      # @return [String]
      def setof
        @setof ? "setof " : ""
      end

      # Returns source text for strictness
      # @return [String]
      def strictness
        @strict ? "strict" : ""
      end

      # Returns source text for security
      # @return [String]
      def security
        @secdef ? "security definer" : ""
      end

      # Returns source SQL function definition statement
      # @return [String]
      def definition(body)
        [%[create or replace function #{name.quote} (#{arguments})],
         %[ returns #{setof}#{type.quote} as $__PIGGLY__$],
         body,
         %[$__PIGGLY__$ language plpgsql #{strictness} #{security} #{@volatility}]].join("\n")
      end

      # @return [String]
      def signature
        "#{@name}(#{@arg_modes.zip(@arg_types).map{|m,t| "#{m} #{t}" }.join(", ")})"
      end

      # @return [String]
      def source_path(config)
        config.mkpath("#{config.cache_root}/Dumper", "#{@identifier}.plpgsql")
      end

      # @return [String]
      def load_source(config)
        File.read(source_path(config))
      end

      # @return [String]
      alias source load_source

      # @return [void]
      def purge_source(config)
        path = source_path(config)

        FileUtils.rm_r(path) if File.exists?(path)

        file = Compiler::TraceCompiler.new(config).cache_path(path)
        FileUtils.rm_r(file) if File.exists?(file)

        file = Reporter::Base.new(config).report_path(path, ".html")
        FileUtils.rm_r(file) if File.exists?(file)
      end

      # @return [SkeletonProcedure]
      def skeleton
        self
      end

      def skeleton?
        true
      end

      def ==(other)
        other.is_a?(self.class) and 
          other.identifier == identifier
      end
    end

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
