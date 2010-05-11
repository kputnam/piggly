module Piggly
  #
  # Coverage is tracked by attaching these compiler-generated tags to various nodes in a stored
  # procedure's parse tree. These tags each have a unique string identifier which is printed by
  # various parts of the recompiled stored procedure, and the output is then recognized by
  # Profile.notice_processor, which calls #ping on the tag corresponding to the printed string.
  #
  # After test execution is complete, each AST is walked and Tag values attached to NodeClass
  # values are used to produce the coverage report
  #
  module Tags

    class AbstractTag
      PATTERN = /[0-9a-f]{16}/

      attr_accessor :id

      def initialize(prefix = nil, id = nil)
        @id = Digest::MD5.hexdigest(prefix.to_s + (id || object_id).to_s).slice(0, 16)
      end

      alias to_s id

      # Defined here in case ActiveSupport hasn't defined it on Object
      def tap
        yield self
        self
      end
    end

    class EvaluationTag < AbstractTag
      attr_reader :ran
     
      def initialize(*args)
        clear
        super
      end

      def type
        :block
      end

      def ping(value)
        @ran = true
      end

      def style
        "c#{@ran ? '1' : '0'}"
      end
      
      def to_f
        @ran ? 100.0 : 0.0
      end

      def complete?
        @ran
      end

      def description
        @ran ? 'full coverage' : 'never evaluated'
      end

      # Resets code coverage
      def clear
        @ran = false
      end

      def ==(other)
        @id == other.id and @ran == other.ran
      end
    end

    #
    # Tracks a contiguous sequence of statements
    #
    class BlockTag < EvaluationTag
    end

    #
    # Tracks procedure calls, raise exception, exits, returns
    #
    class UnconditionalBranchTag < EvaluationTag
      # aggregate this coverage data with conditional branches
      def type
        :branch
      end
    end

    #
    # Tracks if, catch, case branch, continue when, and exit when statements
    # where the coverage consists of the condition evaluating true and false
    #
    class ConditionalBranchTag < AbstractTag
      attr_reader :true, :false

      def initialize(*args)
        clear
        super
      end

      def type
        :branch
      end

      def ping(value)
        case value
        when 't'; @true  = true
        when 'f'; @false = true
        end
      end

      def style
        "b#{@true ? 1 : 0}#{@false ? 1 : 0 }"
      end

      def to_f
        (@true and @false) ? 100.0 : (@true or @false) ? 50.0 : 0.0
      end

      def complete?
        @true and @false
      end

      def description
        if @true and @false
          'full coverage'
        elsif @true
          'never evaluates false'
        elsif @false
          'never evaluates true'
        else
          'never evaluated'
        end
      end

      def clear
        @true, @false  = false
      end

      def ==(other)
        @id == other.id and @true == other.true and @false == other.false
      end
    end

    #
    # Tracks loops where coverage consists of iterating once, iterating more
    # than once, passing through, and at least one full iteration
    #
    class AbstractLoopTag < AbstractTag
      def self.states
        { # never terminates normally (so @pass must be false)
          0b0000 => 'never evaluated',
          0b0001 => 'iterations always terminate early. loop always iterates more than once',
          0b0010 => 'iterations always terminate early. loop always iterates only once',
          0b0011 => 'iterations always terminate early',
          # terminates normally (one of @pass, @once, @twice must be true)
          0b1001 => 'loop always iterates more than once',
          0b1010 => 'loop always iterates only once',
          0b1011 => 'loop never passes through',
          0b1100 => 'loop always passes through',
          0b1101 => 'loop never iterates only once',
          0b1110 => 'loop never iterates more than once',
          0b1111 => 'full coverage' }
      end

      attr_reader :pass, :once, :twice, :ends, :count

      def initialize(*args)
        clear
        super
      end

      def type
        :loop
      end

      def style
        "l#{[@pass, @once, @twice, @ends].map{|b| b ? 1 : 0}}"
      end

      def to_f
        # value space:
        #    (1,2,X)  - loop iterated at least twice and terminated normally
        #    (1,X)    - loop iterated only once and terminated normally
        #    (0,X)    - loop never iterated and terminated normally (pass-thru)
        #    ()       - loop condition was never executed
        #
        # these combinations are ignored, because adding tests for them will probably not reveal bugs
        #    (1,2)    - loop iterated at least twice but terminated early
        #    (1)      - loop iterated only once but terminated early
        100 * ([@pass, @once, @twice, @ends].count{|x| x } / 4.0)
      end

      def complete?
        @pass and @once and @twice and @ends
      end

      def description
        self.class.states.fetch(n = state, "unknown tag state: #{n}")
      end

      # Returns state represented as a 4-bit integer
      def state
        [@ends,@pass,@once,@twice].reverse.inject([0,0]){|(k,n), bit| [k + 1, n | (bit ? 1 : 0) << k] }.last
      end

      def clear
        @pass  = false
        @once  = false
        @twice = false
        @ends  = false
        @count = 0
      end

      def ==(other)
        @id    == other.id   and
        @ends  == other.ends and
        @pass  == other.pass and
        @once  == other.once and
        @twice == other.twice
      end
    end

    #
    # Tracks loops that have a boolean condition in the loop statement (while loops)
    #
    class ConditionalLoopTag < AbstractLoopTag
      def ping(value)
        case value
        when 't'
          # loop iterated
          @count += 1
        else
          # loop terminated
          case @count
          when 0; @pass  = true
          when 1; @once  = true
          else;   @twice = true
          end
          @count = 0

          # this isn't accurate. there needs to be a signal at the end
          # of the loop body to indicate it was reached. otherwise its
          # possible each iteration restarts early with 'continue'
          @ends  = true
        end
      end
    end

    #
    # Tracks loops that don't have a boolean condition in the loop statement (loop and for loops)
    #
    class UnconditionalLoopTag < AbstractLoopTag
      def self.states
        super.merge \
          0b0100 => 'loop always passes through'
      end

      def ping(value)
        case value
        when 't'
          # start of iteration
          @count += 1
        when '@'
          # end of iteration
          @ends = true
        when 'f'
          # loop exit
          case @count
          when 0; @pass = true
          when 1; @once = true
          else;  @twice = true
          end
          @count = 0
        end
      end
    end

  end
end
