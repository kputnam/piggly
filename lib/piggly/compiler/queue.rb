module Piggly

  #
  # Executes blocks in parallel subprocesses
  #
  class Queue

    def self.children=(value)
      @children = value
    end

    # add a compile job to the queue
    def self.queue(&block)
      (@queue ||= []) << block
    end

    def self.child
      queue { yield }
    end

    # start scheduler thread
    def self.start
      @active     = 0
      @children ||= 1
      @queue    ||= []

      while block = @queue.shift
        if @active >= @children
          pid = Process.wait
          @active -= 1
        end

        # enable enterprise ruby feature
        GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

        # use exit! to avoid auto-running any test suites
        pid = Process.fork{ block.call; exit! 0 }

        @active += 1
      end

      Process.waitall
    end

  end
end
