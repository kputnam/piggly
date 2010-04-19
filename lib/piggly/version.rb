module Piggly
  module VERSION
    MAJOR = 1
    MINOR = 2
    TINY  = 0

    STRING = [MAJOR, MINOR, TINY].join('.')

    RELEASE_DATE = '2010-04-19'

    def self.to_s
      STRING
    end
  end
end
