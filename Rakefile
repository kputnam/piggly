begin
  require "rubygems"
  require "bundler/setup"
rescue LoadError
  warn "couldn't load bundler:"
  warn "  #{$!}"
end

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

task :default => :spec
