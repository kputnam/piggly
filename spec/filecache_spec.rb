require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Piggly

  describe File, "cache invalidation" do
    before do
      mtime = Hash['a' => 1,  'b' => 2,  'c' => 3]
      File.stub!(:mtime).and_return{|f| mtime.fetch(f) }
      File.stub!(:exists?).and_return{|f| mtime.include?(f) }
    end

    it "invalidates non-existant cache file" do
      File.stale?('d', 'a').should == true
      File.stale?('d', 'a', 'b').should == true
    end

    it "performs validation using file mtimes" do
      File.stale?('c', 'b').should_not be_true
      File.stale?('c', 'a').should_not be_true
      File.stale?('c', 'b', 'a').should_not be_true
      File.stale?('c', 'a', 'b').should_not be_true

      File.stale?('b', 'a').should_not be_true
      File.stale?('b', 'c').should be_true
      File.stale?('b', 'a', 'c').should be_true
      File.stale?('b', 'c', 'a').should be_true

      File.stale?('a', 'b').should be_true
      File.stale?('a', 'c').should be_true
      File.stale?('a', 'b', 'c').should be_true
      File.stale?('a', 'c', 'b').should be_true
    end

    it "assumes sources exist" do
      lambda{ File.stale?('a', 'd') }.should raise_error(StandardError)
      lambda{ File.stale?('c', 'a', 'x') }.should raise_error(StandardError)
    end
  end  

  class ExampleClass; include FileCache; end
  class ExampleCacheClass; include FileCache; end
  class PigglyExampleClassHTML; include FileCache; end
  class PigglyExampleHTMLClass; include FileCache; end
  class HTMLPiggly; include FileCache; end
  class ExampleRedefined
    include FileCache
    def self.cache_path(file)
      'redefined'
    end
  end

  describe FileCache do
    it "installs class methods" do
      ExampleClass.should respond_to(:cache_path)
    end
    
    it "uses class name as cache subdirectory" do
      Config.cache_root = '/'
      FileUtils.should_receive(:makedirs).at_least(:once)

      ExampleClass.cache_path('a.ext').should           =~ %r(/Example/a.ext$)
      ExampleCacheClass.cache_path('a.ext').should      =~ %r(/ExampleCache/a.ext$)
      PigglyExampleClassHTML.cache_path('a.ext').should =~ %r(/PigglyExampleClassHTML/a.ext$)
      PigglyExampleHTMLClass.cache_path('a.ext').should =~ %r(/PigglyExampleHTML/a.ext$)
      HTMLPiggly.cache_path('a.ext').should             =~ %r(/HTML/a.ext$)
      ExampleRedefined.cache_path('a.ext').should       == 'redefined'
    end
  end

end
