# rewrite a = b => a := b
# rewrite if(...) => if ...
# 

module Piggly
  class RewriteCompiler
    include FileCache
    include CompilerCache

    def self.compile(tree)
      new(profile).send(:compile)
    end

    def self.compiler_path
      __FILE__
    end

    private

    def compile(tree)
    end

  end
end
