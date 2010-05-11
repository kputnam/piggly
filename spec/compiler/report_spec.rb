require 'spec_helper'

module Piggly

  describe Compiler::Report do
    describe "compile" do
      context "when trace cache is stale" do
        it "does not request the trace compiler output"
        it "returns nil"
      end

      context "when trace cache is fresh" do
        it "recurses the children of non-terminal node"
        it "does not recurse terminal nodes"

        it "marks tagged terminal nodes"
        it "does not mark untagged terminal nodes"

        it "marks tagged non-terminal nodes"
        it "does not mark untagged non-terminal nodes"
      end
    end
  end

end
