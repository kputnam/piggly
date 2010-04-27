require 'yaml'

module Piggly
  module Dumper

    #
    # The index file stores metadata about every procedure, but the source
    # code is stored in a separate file for each procedure.
    #
    class Index
      attr_reader :path

      def initialize(path)
        @path  = path
        @index = load
      end

      # Updates the index with the given list of Procedure values
      def update(procedures)
        # purge each procedure's related files from the file system
        outdated(procedures).each(&:purge_source)

        # write each updated procedure's source code
        updated(procedures).each(&:store_source)
        created(procedures).each(&:store_source)

        @index = procedures.index_by(&:oid)

        store
      end

      # Returns a list of Procedure values from the index
      def procedures
        @index.values
      end

      # Returns the Procedure with the given oid
      def [](oid)
        @index[oid].dup
      end

    protected

      # Returns procedures which have differences between the entry in
      # the index and the entry in the given list
      def updated(procedures)
        procedures.select{|p| @index.include?(p.oid) and p != @index[p.oid] }
      end

      # Returns procedures in the index that don't exist in the given list
      def outdated(procedures)
        index = procedures.index_by(&:oid)
        @index.values.reject{|p| index.include?(p.oid) }
      end

      # Returns procedures in the given list that don't exist in the index
      def created(procedures)
        procedures.reject{|p| @index.include?(p.oid) }
      end

    private

      def load
        if File.exists?(@path)
          YAML.load(File.read(@path)).each do |p|
            # read each procedure's source code
            p.source = File.read(p.source_path)
          end.index_by(&:oid)
        else
          Hash.new
        end
      end

      def store
        # remove each procedure's source code before writing the index
        File.open(@path, 'wb'){|io| YAML.dump(procedures.map{|o| o.dup.tap{|c| c.source = nil }}, io) }
      end

    end
  end
end
