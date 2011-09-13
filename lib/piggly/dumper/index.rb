module Piggly
  module Dumper

    #
    # The index file stores metadata about every procedure, but the source
    # code is stored in a separate file for each procedure.
    #
    class Index

      def initialize(config)
        @config = config
      end

      # @return [String]
      def path
        @config.mkpath("#{@config.cache_root}/Dumper", "index.yml")
      end

      # Updates the index with the given list of Procedure values
      # @return [void]
      def update(procedures)
        newest = Util::Enumerable.index_by(procedures){|x| x.identifier }

        removed = index.values.reject{|p| newest.include?(p.identifier) }
        removed.each{|p| p.purge_source(@config) }

        added = procedures.reject{|p| index.include?(p.identifier) }
        added.each{|p| p.store_source(@config) }

        changed = procedures.select do |p|
          if mine = index[p.identifier]
            # If both are skeletons, they will have the same source because they
            # are read from the same file, so don't bother checking that case
            not (mine.skeleton? and p.skeleton?) and
              mine.source(@config) != p.source(@config)
          end
        end
        changed.each{|p| p.store_source(@config) }

        @index = newest
        store_index
      end

      # Returns a list of Procedure values from the index
      def procedures
        index.values
      end

      # Returns the Procedure with the given identifier
      def [](identifier)
        p = index[identifier]
        p.dup if p
      end

      # Returns the shortest human-readable label that distinctly identifies
      # the given procedure from the other procedures in the index
      def label(procedure)
        others =
          procedures.reject{|p| p.oid == procedure.oid }

        same =
          others.all?{|p| p.name.schema == procedure.name.schema }

        name =
          if same
            procedure.name.name
          else
            procedure.name.to_s
          end

        samenames =
          others.select{|p| p.name == procedure.name }

        if samenames.empty?
          # Name is unique enough
          name.to_s
        else
          sameargs =
            samenames.select{|p| p.arg_types == procedure.arg_types }

          if sameargs.empty?
            # Name and arg types are unique enough
            "#{name}(#{procedure.arg_types.join(", ")})"
          else
            samemodes =
              sameargs.select{|p| p.arg_modes == procedure.arg_modes }

            if samemodes.empty?
              # Name, arg types, and arg modes are unique enough
              "#{name}(#{procedure.arg_modes.zip(procedure.arg_types).map{|a,b| "#{a} #{b}" }.join(", ")})"
            end
          end
        end
      end

    private

      def index
        @index ||= load_index
      end

      # Load the index from disk
      def load_index
        contents =
          unless File.exists?(path)
            []
          else
            YAML.load(File.read(path))
          end

        Util::Enumerable.index_by(contents){|x| x.identifier }
      end

      # Write the index to disk
      def store_index
        File.open(path, "wb"){|io| YAML.dump(procedures.map{|p| p.skeleton }, io) }
      end

    end
  end
end
