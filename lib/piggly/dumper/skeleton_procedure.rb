module Piggly
  module Dumper

    #
    # Encapsulates all the information about a stored procedure, except the
    # procedure's source code, which is assumed to be on disk, loaded as needed.
    #
    class SkeletonProcedure

      attr_reader :oid, :name, :type, :arg_types, :arg_modes, :arg_names,
        :strict, :type, :setof, :volatility, :secdef, :identifier, :table_return

      def initialize(oid, name, strict, secdef, setof, type, volatility, arg_modes, arg_names, arg_types, arg_defaults)
        @oid, @name, @strict, @secdef, @type, @volatility, @setof, @arg_modes, @arg_names, @arg_types, @arg_defaults =
          oid, name, strict, secdef, type, volatility, setof, arg_modes, arg_names, arg_types, arg_defaults

        @identifier = Digest::MD5.hexdigest(signature)
	#Check if the procedure is returning a table.
        @table_return = @arg_modes.include?('t') && @setof && @type == 'record' 
      end

      # Returns source text for argument list
      # @return [String]
      def arguments
        @arg_types.zip(@arg_names, @arg_modes, @arg_defaults)
                  .reject{|i| i[2] == 't'} #mode 't' are columns for RETURNS TABLE
                  .map do |type, name, mode, default|
           "#{mode + " " if mode}#{name.quote + " " if name}#{type}#{" DEFAULT " + default if default}"
        end.join(", ")
      end

      # Returns the return definition
      def returns
        if @table_return then
           columns = @arg_types.zip(@arg_names,@arg_modes)
                               .select{ |i| i[2] == 't'}
                               .map do |type,name,mode|
                "#{name} #{type}"
            end.join(", ")
                           
           "table(#{columns})"
        else
           "#{setof}#{type.quote}"
        end
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
         %[ returns #{returns} as $__PIGGLY__$],
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

  end
end
