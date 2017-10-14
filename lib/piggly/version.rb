module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 2
    TINY  = 1

    RELEASE_DATE = "2017-10-13"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
