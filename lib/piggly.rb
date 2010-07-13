require 'fileutils'
require 'digest/md5'

module Piggly
  autoload :VERSION,    'piggly/version'
  autoload :Config,     'piggly/config'
  autoload :Command,    'piggly/command'
  autoload :Compiler,   'piggly/compiler'
  autoload :Dumper,     'piggly/dumper'
  autoload :Parser,     'piggly/parser'
  autoload :Profile,    'piggly/profile'
  autoload :Installer,  'piggly/installer'
  autoload :Reporter,   'piggly/reporter'
  autoload :Tags,       'piggly/tags'
end

require 'piggly/util'
