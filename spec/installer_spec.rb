require 'spec_helper'

module Piggly

describe Installer do

  before do
    @connection = mock('connection')
    Installer.stub(:connection).and_return(@connection)
  end

  describe "trace" do
    it "compiles, executes, and profiles the procedure" do
      untraced  = 'create or replace function x(char)'
      traced    = 'create or replace function f(int)'
      procedure = stub(:oid => 'oid', :source => untraced)
      result    = {:tags => stub, :code => traced}

      Compiler::Trace.should_receive(:cache).
        with(procedure, procedure.oid).and_return(result)

      procedure.should_receive(:definition).
        with(result[:code]).and_return(traced)

      @connection.should_receive(:exec).
        with(traced)

      Profile.instance.should_receive(:add).
        with(procedure, result[:tags], result)

      Installer.trace(procedure)
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

      Installer.untrace(procedure)
    end
  end

  describe "install_trace_support"
  describe "uninstall_trace_support"

end

end
