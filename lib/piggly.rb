unless defined?(PIGGLY_ROOT)
  PIGGLY_ROOT = File.join(File.dirname(__FILE__), 'piggly')
end

require 'fileutils'
require 'digest/md5'
require File.join(PIGGLY_ROOT, 'version')
require File.join(PIGGLY_ROOT, 'config')
require File.join(PIGGLY_ROOT, 'cacheable')
require File.join(PIGGLY_ROOT, 'compiler')
require File.join(PIGGLY_ROOT, 'parser')
require File.join(PIGGLY_ROOT, 'profile')
require File.join(PIGGLY_ROOT, 'installer')
require File.join(PIGGLY_ROOT, 'reporter')
require File.join(PIGGLY_ROOT, 'util')

# used to generate MD5 tags for AST nodes
$PIGGLY_GENTAG = 0
