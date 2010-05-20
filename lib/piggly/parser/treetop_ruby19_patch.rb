module Treetop
  module Runtime
    class CompiledParser

      class Regexp < ::Regexp
        def initialize(*args)
          if args.size == 1
            super(args.first, nil, 'n')
          else
            super
          end
        end
      end if RUBY_VERSION >= '1.9.0'

    end
  end
end
