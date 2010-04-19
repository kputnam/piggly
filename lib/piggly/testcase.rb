require 'test/unit'

module Piggly
  class TestCase < Test::Unit::TestCase

    def self.inherited(subclass)
      # match proc file to test file name rather than test class, for case sensitivity
      proc_name = File.basename(caller.first[/^(.+):/, 1], '_test.rb')
      source_files[subclass] = proc_name + '.sql'
    end

    def self.source_file=(path)
      source_files[self] = path
    end

    def self.source_file
      source_files[self]
    end

    def self.source_files
      @@source_files ||= {}
    end

  end
end
