require File.join(File.dirname(__FILE__), 'lib', 'piggly', 'version')
  
module Piggly
  def self.gemspec
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

      s.has_rdoc = false
      s.bindir   = 'bin'
      s.executables  = %w[piggly]
      s.require_path = 'lib'
      s.add_dependency 'treetop'
      s.add_dependency 'pg'
    end
  end
end
