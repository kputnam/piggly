class File
  class << self

    # True if target file is older (by mtime) than any source file
    def stale?(target, *sources)
      if exists?(target)
        oldest = mtime(target)
        sources.any?{|x| mtime(x) > oldest }
      else
        true
      end
    end

  end
end
