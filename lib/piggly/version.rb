module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 2
    TINY  = 4

    RELEASE_DATE = "2017-11-01"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
