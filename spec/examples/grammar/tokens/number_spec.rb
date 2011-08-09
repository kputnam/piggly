require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper
 
    describe "numbers" do
      it "can be an integer in binary notation" do
        node = parse(:tNumber, "B'0'")
      end

      it "can be an integer in hexadecimal notation" do
        node = parse(:tNumber, "X'F'")
      end

      it "can be an integer in decimal notation" do
        node = parse(:tNumber, '11223344556677889900')
      end

      it "can be a real number in decimial notation" do
        node = parse(:tNumber, '3.2267')
      end

      it "can be a real number in scientific notation" do
        node = parse(:tNumber, '1.3e3')
      end

      it "can be an integer in scientific notation" do
        node = parse(:tNumber, '5e4')
      end
    end

  end
end
