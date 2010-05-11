require 'spec_helper'

module Piggly

  describe Compiler::Cacheable do

    describe "stale?" do
    end

    describe "cache" do
      context "when cache doesn't exist" do
        it "parses the procedure source"
        it "passes the parse tree and transient arguments to the compiler"
        it "updates the cache with the results from the compiler"
        it "returns the cache object"
      end

      context "when cache is stale" do
        it "parses the procedure source"
        it "passes the parse tree and transient arguments to the compiler"
        it "updates the cache with the results from the compiler"
        it "returns the cache object"
      end

      context "when cache is fresh" do
        it "retrieves the cached results from disk"
        it "returns the cache object"
      end
    end

  end

  describe Compiler::Cacheable::CacheDirectory do
    describe "[]=" do
      it "stores the new entry"
      it "writes through to disk"
    end

    describe "update" do
      it "stores new entries"
      it "stores updated entries"
      it "writes through to disk"
    end

    describe "replace" do
      it "stores new entries"
      it "stores updated entries"
      it "removes previous entries"
      it "writes through to disk"
    end

    describe "clear" do
      it "removes all entries"
      it "writes through to disk"
    end

    describe "[]" do
      context "when entry is not already in memory" do
        it "reads the entry from disk"
        it "stores the entry in memory"
        it "returns the associated value"
      end

      context "when entry is already in memory" do
        it "does not read the entry from disk"
        it "returns the associated value"
      end
    end

    describe "keys"
  end

end
