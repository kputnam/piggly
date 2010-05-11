require 'spec_helper'

module Piggly

describe Config do
  it "has class accessors and mutators" do
    Config.should respond_to(:cache_root)
    Config.should respond_to(:cache_root=)
    Config.should respond_to(:report_root)
    Config.should respond_to(:report_root=)
    Config.should respond_to(:trace_prefix)
    Config.should respond_to(:trace_prefix=)
  end

  it "has default values" do
    Config.cache_root = nil
    Config.cache_root.should_not be_nil
    Config.cache_root.should =~ /cache$/

    Config.report_root = nil
    Config.report_root.should_not be_nil
    Config.report_root.should =~ /reports$/

    Config.trace_prefix = nil
    Config.trace_prefix.should_not be_nil
    Config.trace_prefix.should == 'PIGGLY'
  end
  
  describe "path" do
    it "doesn't reparent absolute paths" do
      Config.path('/tmp', '/usr/bin/ps').should == '/usr/bin/ps'
      Config.path('A:/data/tmp', 'C:/USER/tmp').should == 'C:/USER/tmp'
      Config.path('/tmp/data', '../data.txt').should == '../data.txt'
    end
    
    it "reparents relative paths" do
      Config.path('/tmp', 'note.txt').should == '/tmp/note.txt'
    end
    
    it "doesn't require path parameter" do
      Config.path('/tmp').should == '/tmp'
    end
  end
  
  describe "mkpath" do
    it "creates root if doesn't exist" do
      FileUtils.should_receive(:makedirs).with('x/y').once.and_return(true)
      Config.mkpath('x/y', 'z')
    end

    it "throws an error on path components that exist as files" do
      lambda { Config.mkpath('/etc/passwd/file') }.should raise_error(Errno::EEXIST)
    end
  end
end

end
