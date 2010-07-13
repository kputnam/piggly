begin
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.spec_opts << '--color'
    t.spec_opts << '--format=progress'
  end

  task :default => :spec
rescue LoadError
end

require 'rake/gempackagetask'
load './piggly.gemspec'
Rake::GemPackageTask.new(Piggly.gemspec) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end
