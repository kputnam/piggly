require 'spec_helper'

module Piggly

  describe Util::Cacheable do

    class ExampleClass;           include Util::Cacheable; end
    class ExampleCacheClass;      include Util::Cacheable; end
    class PigglyExampleClassHTML; include Util::Cacheable; end
    class PigglyExampleHTMLClass; include Util::Cacheable; end
    class HTMLPiggly;             include Util::Cacheable; end
    class ExampleRedefined
      include Util::Cacheable
      def self.cache_path(file)
        'redefined'
      end
    end

    before do
      Config.stub(:cache_root).and_return('/')
    end

    it "installs class methods" do
      ExampleClass.should respond_to(:cache_path)
    end
    
    it "uses class name as cache subdirectory" do
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
