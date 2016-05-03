require_relative 'lib/piggly/version'

Gem::Specification.new do |s|
  s.name     = 'piggly'
  s.description = 'PostgreSQL PL/pgSQL stored procedure code coverage'
  s.version  = Piggly::VERSION.to_s
  s.author   = 'Kvle Putnam'
  s.email    = 'putnam.kvle@gmail.com'
  s.summary  = 'PL/pgSQL code coverage tool'
  s.homepage = 'http://github.com/kputnam/piggly'
  s.files    = ['README*', 'Rakefile', '{spec,lib,bin}/**/*'].map{|p| Dir[p]}.flatten
  s.files   -= ['lib/piggly/parser/parser.rb']
  s.license  = 'BSD-2-Clause'

  s.has_rdoc = false
  s.bindir   = 'bin'
  s.executables  = %w[piggly]
  s.require_path = 'lib'
  s.add_dependency 'treetop', '~> 1.4.14'
  s.add_dependency 'pg',      '~> 0.18.4'
end
