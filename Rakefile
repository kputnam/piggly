begin # rspec-2
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new do |t|
    t.verbose    = false
    t.pattern    = "spec/**/*_spec.rb"
    t.rspec_opts = "--color --format=p"
  end
rescue LoadError => first
  begin # rspec-1
    require "spec/rake/spectask"
    Spec::Rake::SpecTask.new do |t|
      t.pattern = "spec/**/*_spec.rb"
      t.spec_opts << "--color"
      t.spec_opts << "--format=p"
    end
  rescue LoadError => second
    task :spec do
      warn "couldn't load rspec version 1 or 2:"
      warn "  #{first}"
      warn "  #{second}"
    end
  end
end

require 'rake/gempackagetask'
load './piggly.gemspec'
Rake::GemPackageTask.new(Piggly.gemspec) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end
