require 'yaml'

module Piggly
  module Dumper

    #
    # The index file stores metadata about every procedure, but the source
    # code is stored in a separate file for each procedure.
    #
    class Index

      def self.path
        @path ||= Piggly::Config.mkpath(File.join(Piggly::Config.cache_root, 'Dumper'), 'index.yml')
      end

      def self.instance
        @instance ||= new
      end

      def initialize
        load
      end

      # Updates the index with the given list of Procedure values
      def update(procedures)
        # purge each procedure's related files from the file system
        changed = outdated(procedures).each(&:purge_source).any?

        # write each updated procedure's source code
        changed ||= updated(procedures).each(&:store_source).any?
        changed ||= created(procedures).each(&:store_source).any?

        @index = procedures.index_by(&:identifier)

        store if changed
      end

      # Returns a list of Procedure values from the index
      def procedures
        @index.values
      end

      # Returns the Procedure with the given identifier
      def [](identifier)
        @index[identifier].dup
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
                if samenames.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.name} (#{procedure.arg_types.join(', ')})"
                elsif samespaces.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.namespace}.#{procedure.name} (#{procedure.arg_types.join(', ')})"
                elsif sametypes.none?{|p| p.arg_types == procedure.arg_types }
                  "#{procedure.type} #{procedure.name} (#{procedure.arg_types.join(', ')})"
                else
                  "#{procedure.type} #{procedure.namespace}.#{procedure.name} (#{procedure.arg_types.join(', ')})"
                end
              end
            end
          end
        end
      end

    protected

      # Returns procedures which have differences between the entry in
      # the index and the entry in the given list
      def updated(procedures)
        procedures.select{|p| @index.include?(p.identifier) and p != @index[p.identifier] }
      end

      # Returns procedures in the index that don't exist in the given list
      def outdated(procedures)
        index = procedures.index_by(&:identifier)
        @index.values.reject{|p| index.include?(p.identifier) }
      end

      # Returns procedures in the given list that don't exist in the index
      def created(procedures)
        procedures.reject{|p| @index.include?(p.identifier) }
      end

    private

      # Load the index from disk
      def load
        updated = false

        @index = 
          if File.exists?(self.class.path)
            YAML.load(File.read(self.class.path)).inject([]) do |list, p|
              if p.identified_using and p.identifier(p.identified_using) != p.identifier
                # update location
                p.rename(p.identifier(p.identified_using))
                updated = true
              end

              begin
                # read each procedure's source code
                p.source = File.read(p.source_path)
                list << p
              rescue Errno::ENOENT
                puts "Failed to load source for #{p.name}"
                list
              end
            end.index_by(&:identifier)
          else
            Hash.new
          end

        store if updated
      end

      # Write the index to disk
      def store
        # remove each procedure's source code before writing the index
        File.open(self.class.path, 'wb'){|io| YAML.dump(procedures.map{|o| o.dup.tap{|c| c.source = nil }}, io) }
      end

    end
  end
end
