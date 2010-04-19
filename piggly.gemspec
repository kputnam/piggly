require File.join(File.dirname(__FILE__), 'lib', 'piggly', 'version')
  
module Piggly
  def self.gemspec
    Gem::Specification.new do |s|
      s.name     = 'piggly'
      s.description = 'PostgreSQL PL/pgSQL stored procedure code coverage'
      s.version  = Piggly::VERSION::STRING
      s.author   = 'Kyle Putnam'
      s.email    = 'putnam.kyle@gmail.com'
      s.summary  = 'PL/pgSQL code coverage tool'
      s.homepage = 'http://github.com/kputnam/piggly'
      s.files    = ['README*', 'Rakefile', '{spec,lib,bin}/**/*'].map{|p| Dir[p]}.flatten
      s.bindir   = 'bin'
      s.executables  = %w[piggly]
      s.require_path = 'lib'
      s.has_rdoc = false
      s.add_dependency 'treetop'
    end
  end
end
