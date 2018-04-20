module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 3
    TINY  = 0

    RELEASE_DATE = "2018-04-20"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
