module Piggly
  module Dumper

    #
    # The index file stores metadata about every procedure, but the source
    # code is stored in a separate file for each procedure.
    #
    class Index

      def initialize(config)
        @config = config
        @index  = load_index
      end

      # @return [String]
      def path
        @config.mkpath("#{@config.cache_root}/Dumper", "index.yml")
      end

      # Updates the index with the given list of Procedure values
      # @return [void]
      def update(procedures)
        newest = Util::Enumerable.index_by(procedures){|x| x.identifier }

        removed = @index.values.reject{|p| newest.include?(p.identifier) }
        removed.each{|p| p.purge_source(@config) }

        added = procedures.reject{|p| @index.include?(p.identifier) }
        added.each{|p| p.store_source(@config) }

        changed = procedures.select do |p|
          if mine = @index[p.identifier]
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
        @index.values
      end

      # Returns the Procedure with the given identifier
      def [](identifier)
        p = @index[identifier]
        p.dup if p
      end

      # Returns the shortest human-readable label that distinctly identifies
      # the given procedure from the other procedures in the index
      def label(procedure)
        others    = procedures.reject{|p| p.oid == procedure.oid }
        samenames = others.select{|p| p.name == procedure.name }
        if samenames.none?
          procedure.name
        else
          # same name and namespace
          samespaces = samenames.select{|p| p.namespace == procedure.namespace }
          if samespaces.none?
            "#{procedure.namespace}.#{procedure.name}"
          else
            # same name and return type
            sametypes = samenames.select{|p| p.type == procedure.type }
            if sametypes.none?
              "#{procedure.type} #{procedure.name}"
            else
              # same name, namespace, and return type
              if samespaces.none?{|p| p.type == procedure.type }
                "#{procedure.type} #{procedure.namespace}.#{procedure.name}"
              else
                # ignore OUT arguments
                args = procedure.arg_types.zip(procedure.arg_modes).
                  select{|_, m| m != "out" }.map{|x| x.first }.join(", ")

                if samenames.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.name} (#{args})"
                elsif samespaces.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.namespace}.#{procedure.name} (#{args})"
                elsif sametypes.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.type} #{procedure.name} (#{args})"
                else
                  "#{procedure.type} #{procedure.namespace}.#{procedure.name} (#{args})"
                end
              end
            end
          end
        end
      end

    private

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
