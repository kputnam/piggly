require 'spec_helper'

module Piggly

describe Profile do

  before do
    @profile = Profile.instance
  end

  describe "notice_processor" do
    it "returns a function" do
      Profile.notice_processor.should be_a(Proc)
    end

    context "when message matches PATTERN" do
      context "with no optional value" do
        it "pings the corresponding tag" do
          message = "WARNING:  #{Config.trace_prefix} 0123456789abcdef"
          @profile.should_receive(:ping).
            with('0123456789abcdef', nil)

          Profile.notice_processor.call(message)
        end
      end

      context "with an optional value" do
        it "pings the corresponding tag" do
          message = "WARNING:  #{Config.trace_prefix} 0123456789abcdef X"
          @profile.should_receive(:ping).
            with('0123456789abcdef', 'X')

          Profile.notice_processor.call(message)
        end
      end
    end

    context "when message doesn't match PATTERN" do
      it "prints the message to stderr" do
        message = "WARNING:  Parameter was NULL and I don't like it!"
        $stderr.should_receive(:puts).with(message)

        Profile.notice_processor.call(message)
      end
    end
  end

  describe "add" do
    before do
      @first  = mock('first tag',  :id => 'first')
      @second = mock('second tag', :id => 'second')
      @third  = mock('third tag',  :id => 'third')
      @cache  = mock('Compiler::Cacheable::CacheDirectory')
      @procedure = mock('procedure', :oid => 'oid')
    end

    context "without cache parameter" do
      it "indexes each tag by id" do
        @profile.add(@procedure, [@first, @second, @third])
        @profile.by_id[@first.id].should == @first
        @profile.by_id[@second.id].should == @second
        @profile.by_id[@third.id].should == @third
      end

      it "indexes each tag by procedure" do
        @profile.add(@procedure, [@first, @second, @third])
        @profile.by_procedure[@procedure.oid].should == [@first, @second, @third]
      end
    end

    context "with cache parameter" do
      it "indexes each tag by id" do
        @profile.add(@procedure, [@first, @second, @third], @cache)
        @profile[@first.id].should == @first
        @profile[@second.id].should == @second
        @profile[@third.id].should == @third
      end

      it "indexes each tag by procedure" do
        @profile.add(@procedure, [@first, @second, @third])
        @profile.by_procedure[@procedure.oid].should == [@first, @second, @third]
      end

      it "indexes each tag by cache" do
        @profile.add(@procedure, [@first, @second, @third], @cache)
        @profile.by_cache[@cache].should == [@first, @second, @third]
      end
    end
  end

  describe "ping" do
    context "when tag isn't in the profile" do
      it "raises an exception" do
        @profile.stub(:by_id).and_return(Hash.new)
        lambda do
          @profile.ping('0123456789abcdef')
        end.should raise_error('No tag with id 0123456789abcdef')
      end
    end

    context "when tag is in the profile" do
      before do
        @tag  = mock('tag', :id => '0123456789abcdef')
        index = Hash[@tag.id => @tag]
        @profile.stub(:by_id).and_return(index)
      end

      it "calls ping on the corresponding tag" do
        @tag.should_receive(:ping).with('X')
        @profile.ping(@tag.id, 'X')
      end
    end
  end

  describe "summary" do
    context "when given a procedure" do
    end

    context "when not given a procedure" do
    end
  end

  describe "clear" do
    before do
      @first  = mock('first tag',  :id => 'first')
      @second = mock('second tag', :id => 'second')
      @third  = mock('third tag',  :id => 'third')
      index   = { @first.id  => @first,
                  @second.id => @second,
                  @third.id  => @third }
      @profile.stub(:by_id).
        and_return(index)
    end

    it "calls clear on each tag" do
      @first.should_receive(:clear)
      @second.should_receive(:clear)
      @third.should_receive(:clear)
      @profile.clear
    end
  end

  describe "store" do
  end

  describe "empty?" do
  end

  describe "difference" do
  end

end

end
