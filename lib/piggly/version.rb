module Piggly
  module VERSION
    MAJOR = 1
    MINOR = 2
    TINY  = 1

    STRING = [MAJOR, MINOR, TINY].join('.')

    RELEASE_DATE = '2010-04-22'

    def self.to_s
      STRING
    end
  end
end
