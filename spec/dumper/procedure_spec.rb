require 'spec_helper'

module Piggly
  
  describe Dumper::ReifiedProcedure do
    describe "all" do
      before do
        # stub connection
      end
    end

    describe "from_hash" do
      it "abbreviates known return types"
      it "leaves alone unknown argument types"

      it "abbreviates known return types"
      it "leaves alone unknown argument types"

      it "maps known volatilities"
      it "leaves alone unknown volatilities"

      it "maps known argument modes"
      it "leaves alone unknown argument modes"
    end

    describe "store_source" do
      context "when source is already instrumented" do
        it "raises an error"
      end

      context "when the procedure was identified using the current configuration setting" do
        it "does not attempt to remove any files"
        it "writes to the current location"
        it "has the current identified_using property"
      end

      context "when the procedure was identified using some other configuration setting" do
        it "removes any old report files"
        it "removes any old trace cache files"
        it "removes the old source cache files"
        it "writes to the current location"
        it "updates the identified_using property"
      end
    end
  end

  describe Dumper::SkeletonProcedure do
    describe "definition" do
      it "specifies namespace and function name"
      it "specifies source code between dollar-quoted string tags"

      context "with argument modes" do
        it "specifies argument modes"
      end

      context "without argument modes" do
        it "doesn't specify argument modes"
      end

      context "with strict modifier" do
        it "specifies STRICT token"
      end

      context "without strict modifier" do
        it "doesn't specify STRICT token"
      end

      context "with security definer modifier" do
        it "specifies SECURITY DEFINER token"
      end

      context "without security definer modifier" do
        it "doesn't specify SECURITY DEFINER token"
      end

      context "with set-returning type" do
        it "specifies SETOF token"
      end

      context "without non set-returning type" do
        it "doesn't specify SETOF token"
      end

      context "with stable volatility" do
        it "specifies STABLE token"
      end
    end

    describe "source_path" do
      it "has a .plpgsql extension"
      it "is within the Dumper directory"
    end

    describe "purge_source" do
      context "when the procedure was identified using the current configuration setting" do
        it "removes any old report files"
        it "removes any old trace cache files"
        it "removes the old source cache files"
        it "removes the current report files"
        it "removes the current trace cache files"
        it "removes the current source cache files"
        it "doesn't attempt to remove any other files"
      end

      context "when the procedure was identified using some other configuration setting" do
        it "removes the current report files"
        it "removes the current trace cache files"
        it "removes the current source cache files"
        it "doesn't attempt to remove any other files"
      end
    end

    describe "equality operator"
  end

end
