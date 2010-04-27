module Piggly
  module Dumper
    class << self

      #
      # Change --proc-paths to actually execute the SQL files, and then use
      # Procedure.all to retrieve their definitions.  This saves having to
      # parse the CREATE PROCEDURE statement. 
      #
      # Once the procedures are synchronized to the disk cache, we need the
      # Procedure.all index to reconstruct the CREATE PROCEDURE statement with
      # the rewritten source.
      #
      # This entails updates to the grammar, and that the parser will now
      # read the dumped source code, without the CREATE PROCEDURE bits, so
      # the Installer will have to know to reconstruct that part.
      #
      
      # Installer.trace(procedure)
      # Installer.untrace(procedure)
      # Parser.cache(path)
      # Parser.parse(content)

      def dump
        index.update(Piggly::Dumper::Procedure.all)
      end

      def index
      end

      def procedures
        index.procedures
      end

    end
  end
end

require File.join(File.dirname(__FILE__), *%w[dumper index])
require File.join(File.dirname(__FILE__), *%w[dumper procedure])
