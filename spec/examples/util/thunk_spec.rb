require 'spec_helper'

module Piggly

  describe Util::Thunk do

    context "not already evaluated" do
      before do
        @work  = mock('computation')
        @thunk = Util::Thunk.new { @work.evaluate }
      end

      it "responds to thunk? without evaluating" do
        @work.should_not_receive(:evaluate)
        @thunk.thunk?.should be_true
      end

      it "evaluates when force! is explicitly called" do
        @work.should_receive(:evaluate).and_return(@work)
        @thunk.force!.should == @work
      end

      it "evaluates when some other method is called" do
        @work.should_receive(:evaluate).and_return(@work)
        @work.should_receive(:something).and_return(@work)
        @thunk.something.should == @work
      end
    end

    context "previously evaluated" do
      before do
        @work = mock('computation')
        @work.stub(:evaluate).and_return(@work)

        @thunk = Util::Thunk.new { @work.evaluate }
        @thunk.force!
      end

      it "responds to thunk? without evaluating" do
        @work.should_not_receive(:evaluate)
        @thunk.thunk?.should be_true
      end

      it "should not re-evaluate when force! is called" do
        @work.should_not_receive(:evaluate)
        @thunk.force!
      end

      it "should not re-evaluate when some other method is called" do
        @work.should_not_receive(:evaluate)
        @work.should_receive(:something).and_return(@work)
        @thunk.something.should == @work
      end
    end

  end

end
