module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 0
    TINY  = 0

    RELEASE_DATE = "2016-05-03"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
