require 'spec_helper'

module Piggly

describe Config do
  before do
    @config = Config.new
  end

  it "has class accessors and mutators" do
    @config.should respond_to(:cache_root)
    @config.should respond_to(:cache_root=)
    @config.should respond_to(:report_root)
    @config.should respond_to(:report_root=)
    @config.should respond_to(:trace_prefix)
    @config.should respond_to(:trace_prefix=)
  end

  it "has default values" do
    @config.cache_root = nil
    @config.cache_root.should_not be_nil
    @config.cache_root.should =~ /cache$/

    @config.report_root = nil
    @config.report_root.should_not be_nil
    @config.report_root.should =~ /reports$/

    @config.trace_prefix = nil
    @config.trace_prefix.should_not be_nil
    @config.trace_prefix.should == 'PIGGLY'
  end
  
  describe "path" do
    it "doesn't reparent absolute paths" do
      @config.path('/tmp', '/usr/bin/ps').should == '/usr/bin/ps'
      @config.path('A:/data/tmp', 'C:/USER/tmp').should == 'C:/USER/tmp'
      @config.path('/tmp/data', '../data.txt').should == '../data.txt'
    end
    
    it "reparents relative paths" do
      @config.path('/tmp', 'note.txt').should == '/tmp/note.txt'
    end
    
    it "doesn't require path parameter" do
      @config.path('/tmp').should == '/tmp'
    end
  end
  
  describe "mkpath" do
    it "creates root if doesn't exist" do
      FileUtils.should_receive(:makedirs).with('x/y').once.and_return(true)
      @config.mkpath('x/y', 'z')
    end

    it "throws an error on path components that exist as files" do
      lambda { @config.mkpath('/etc/passwd/file') }.should raise_error(Errno::EEXIST)
    end
  end
end

end
