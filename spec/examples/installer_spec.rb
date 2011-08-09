require 'spec_helper'

module Piggly

describe Installer do

  before do
    @config     = Config.new
    @connection = mock('connection')
    @installer  = Installer.new(@config, @connection)
  end

  describe "trace" do
    it "compiles, executes, and profiles the procedure" do
      untraced  = 'create or replace function x(char)'
      traced    = 'create or replace function f(int)'

      result   = {:tags => stub, :code => traced}
      profile  = mock('profile')

      compiler = mock('compiler', :compile => result)
      Compiler::TraceCompiler.should_receive(:new).
        and_return(compiler)

      procedure = mock('procedure', :oid => 'oid', :source => untraced)
      procedure.should_receive(:definition).
        with(traced).and_return(traced)

      @connection.should_receive(:exec).
        with(traced)

      profile.should_receive(:add).
        with(procedure, result[:tags], result)

      @installer.trace(procedure, profile)
    end
  end

  describe "untrace" do
    it "executes the original definition" do
      untraced  = 'create or replace function x(char)'
      procedure = stub(:oid => 'oid', :source => untraced)

      procedure.should_receive(:definition).
        and_return(untraced)

      @connection.should_receive(:exec).
        with(untraced)

      @installer.untrace(procedure)
    end
  end

  describe "install_trace_support"
  describe "uninstall_trace_support"

end

end
