require 'spec_helper'

module Piggly

  describe Compiler::Cacheable do
    before do
      @compiler = Class.new { include Piggly::Compiler::Cacheable }
      @compiler.stub(:name).and_return('TestCompiler')
    end

    describe "stale?" do
      it "compares cache_path with source path and cache_sources" do
        @compiler.stub(:cache_sources).
          and_return(%w(parser.rb grammar.tt nodes.rb))

        @compiler.should_receive(:cache_path).
          with('source.sql').
          and_return('source.cache')

        File.should_receive(:stale?).
          with('source.cache', 'source.sql', 'parser.rb', 'grammar.tt', 'nodes.rb')

        @compiler.stale?('source.sql')
      end
    end

    describe "cache" do
      before do
        @procedure = mock('procedure')
        @procedure.stub(:source_path).and_return('source path')
        @procedure.stub(:source).and_return('SOURCE CODE')
        @procedure.stub(:name).and_return('f')
      end

      context "when cache is stale" do
        before do
          @compiler.should_receive(:stale?).
            and_return(true)

          File.should_receive(:read).
            with(@procedure.source_path).
            and_return(@procedure.source)
        end

        it "parses the procedure source" do
          @compiler.stub(:compile).
            and_return(mock('result', :null_object => true))
          Compiler::Cacheable::CacheDirectory.stub(:lookup).
            and_return(mock('cache', :null_object => true))

          Parser.should_receive(:parse).
            with(@procedure.source)

          @compiler.cache(@procedure)
        end

        it "passes the parse tree and transient arguments to the compiler" do
          tree  = mock('parse tree', :null_object => true)
          args  = %w(a b c)
          block = lambda{|a,b| b }

          Parser.stub(:parse).and_return(tree)
          Compiler::Cacheable::CacheDirectory.stub(:lookup).
            and_return(mock('cache', :null_object => true))

          # calling cache method below should pass the parse tree plus any
          # arguments given to cache along to the abstract 'compile' method
          @compiler.should_receive(:compile).
            with(tree, *args.push(block)).
            and_return(mock('result', :null_object => true))

          @compiler.cache(@procedure, *args, &block)
        end

        it "updates the cache with the results from the compiler" do
          cache  = mock('cache')
          result = mock('result')

          Parser.stub(:parse).
            and_return(mock('parse tree', :null_object => true))
          @compiler.should_receive(:compile).
            # with parse tree
            and_return(result)

          Compiler::Cacheable::CacheDirectory.should_receive(:lookup).
            and_return(cache)
          cache.should_receive(:replace).
            with(result)

          @compiler.cache(@procedure)
        end

        it "returns the cache object" do
          Parser.stub(:parse).
            and_return(mock('parse tree', :null_object => true))
          @compiler.should_receive(:compile).
            and_return(mock('result'))

          cache = mock('cache')
          cache.stub(:replace)

          Compiler::Cacheable::CacheDirectory.should_receive(:lookup).
            and_return(cache)
          
          @compiler.cache(@procedure).should == cache
        end
      end

      context "when cache is fresh" do
        before do
          @compiler.should_receive(:stale?).
            and_return(false)
        end

        it "returns the cached results from disk" do
          cache = mock('cache')
          
          Compiler::Cacheable::CacheDirectory.should_receive(:lookup).
            and_return(cache)
          
          @compiler.cache(@procedure).should == cache
        end
      end
    end
  end

  describe Compiler::Cacheable::CacheDirectory do
    before do
      @cache = Compiler::Cacheable::CacheDirectory.new('directory-path')
    end

    describe "[]=" do
      it "stores the new entry" do
        @cache.stub(:write)
        @cache[:foo] = 'data'
        @cache[:foo].should == 'data'
        @cache['foo'].should == 'data'
      end

      it "writes through to disk" do
        @cache.should_receive(:write).
          with('foo' => 'data')
        @cache['foo'] = 'data'
      end
    end

    describe "update" do
      it "stores new entries" do
        @cache.stub(:write)
        @cache.update(:abc => 'abacus', :xyz => 'xylophone')
        @cache[:abc].should == 'abacus'
        @cache[:xyz].should == 'xylophone'
        @cache['abc'].should == 'abacus'
        @cache['xyz'].should == 'xylophone'
      end

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

  end

end
