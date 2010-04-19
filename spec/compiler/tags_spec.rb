require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Piggly

describe Tag do
end

describe EvaluationTag do
end

describe BlockTag do
end

describe UnconditionalBranchTag do
end

describe LoopConditionTag do
end

describe ForCollectionTag do
  before do
    @tag = ForCollectionTag.new('for-loop')
  end

  it "detects state 00 (0b0000)" do
    # - terminates normally
    # - pass through
    # - iterate only once
    # - iterate more than once
    @tag.state.should == 0b0000
  end

  it "detects state 01 (0b0001)" do
    # - terminates normally
    # - pass through
    # - iterate only once
    # + iterate more than once

    # two iterations
    @tag.ping('t')
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0001
  end

  it "detects state 02 (0b0010)" do
    # - terminates normally
    # - pass through
    # + iterate only once
    # - iterate more than once

    # one iteration
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0010
  end

  it "detects state 03 (0b0011)" do
    # - terminates normally
    # - pass through
    # + iterate only once
    # + iterate more than once

    # one iteration
    @tag.ping('t')
    @tag.ping('f')

    # two iterations
    @tag.ping('t')
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0011
  end

  it "detects state 04 (0b0100)" do
    # - terminates normally
    # + pass through
    # - iterate only once
    # - iterate more than once

    # zero iterations
    @tag.ping('f')

    @tag.state.should == 0b0100
  end

  it "detects state 05 (0b0101)" do
    # - terminates normally
    # + pass through
    # - iterate only once
    # + iterate more than once

    # zero iterations
    @tag.ping('f')

    # two iterations
    @tag.ping('t')
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0101
  end

  it "detects state 06 (0b0110)" do
    # - terminates normally
    # + pass through
    # + iterate only once
    # - iterate more than once

    # zero iterations
    @tag.ping('f')

    # one iteration
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0110
  end

  it "detects state 07 (0b0111)" do
    # - terminates normally
    # + pass through
    # + iterate only once
    # + iterate more than once
    
    # zero iterations
    @tag.ping('f')

    # one iteration
    @tag.ping('t')
    @tag.ping('f')

    # two iterations
    @tag.ping('t')
    @tag.ping('t')
    @tag.ping('f')

    @tag.state.should == 0b0111
  end

  it "detects state 08 (0b1000)" do
    # + terminates normally
    # - pass through
    # - iterate only once
    # - iterate more than once

    # TODO invalid
    @tag.ping('@')

    @tag.state.should == 0b1000
  end

  it "detects state 09 (0b1001)" do
    # + terminates normally
    # - pass through
    # - iterate only once
    # + iterate more than once

    # iterate twice
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1001
  end

  it "detects state 10 (0b1010)" do
    # + terminates normally
    # - pass through
    # + iterate only once
    # - iterate more than once

    # iterate once
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1010
  end

  it "detects state 11 (0b1011)" do
    # + terminates normally
    # - pass through
    # + iterate only once
    # + iterate more than once

    # iterate once
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    # iterate twice
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1011
  end

  it "detects state 12 (0b1100)" do
    # + terminates normally
    # + pass through
    # - iterate only once
    # - iterate more than once

    # TODO invalid
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1100
  end

  it "detects state 13 (0b1101)" do
    # + terminates normally
    # + pass through
    # - iterate only once
    # + iterate more than once

    # iterate twice
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    # pass through
    @tag.ping('f')

    @tag.state.should == 0b1101
  end

  it "detects state 14 (0b1110)" do
    # + terminates normally
    # + pass through
    # + iterate only once
    # - iterate more than once
    
    # pass through
    @tag.ping('f')

    # iterate once
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1110
  end

  it "detects state 15 (0b1111)" do
    # + terminates normally
    # + pass through
    # + iterate only once
    # + iterate more than once

    # pass through
    @tag.ping('f')

    # iterate once
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    # iterate twice
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('t')
    @tag.ping('@')
    @tag.ping('f')

    @tag.state.should == 0b1111
  end

end

describe BranchConditionTag do
end

end
