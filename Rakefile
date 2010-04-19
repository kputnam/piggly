dir = File.dirname(__FILE__)
require 'rubygems'
require 'rake'

begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end
  task :default => :spec
rescue Exception
end

require 'rake/gempackagetask'
load './piggly.gemspec'
Rake::GemPackageTask.new(Piggly.gemspec) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end
