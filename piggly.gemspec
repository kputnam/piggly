require File.join(File.dirname(__FILE__), 'lib', 'piggly', 'version')
  
$gemspec = Gem::Specification.new do |s|
  s.name     = 'piggly'
  s.version  = Piggly::VERSION::STRING
  s.author   = 'Kyle Putnam'
  s.email    = 'kyle.putnam@ppmconnect.com'
  s.summary  = 'Pl/pgSQL code coverage tool'
  s.files    = ['README', 'Rakefile', '{spec,lib,bin}/**/*'].map{|p| Dir[p]}.flatten
  s.bindir   = 'bin'
  s.executables  = %w[piggly]
  s.require_path = 'lib'
  s.has_rdoc = false
  s.add_dependency 'treetop'
end
