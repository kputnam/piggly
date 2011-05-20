module Piggly
  module Command
    autoload :Base,     "piggly/command/base"
    autoload :Report,   "piggly/command/report"
    autoload :Test,     "piggly/command/test"
    autoload :Trace,    "piggly/command/trace"
    autoload :Untrace,  "piggly/command/untrace"
  end
end
