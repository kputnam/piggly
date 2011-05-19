module Piggly
  module VERSION
    MAJOR = 1
    MINOR = 3
    TINY  = 0

    RELEASE_DATE = "2011-05-18"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
