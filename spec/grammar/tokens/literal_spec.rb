require 'spec_helper'

module Piggly
  describe Parser, "tokens" do
    include GrammarHelper
 
    describe "literals" do
      it "can be a cast call on a string" do
        node = parse(:tLiteral, "cast('100.00' as numeric(10, 2))")
        node = parse(:tLiteral, "cast( '100.00' as numeric (10, 2) )")
      end

      it "can be a cast call on a number" do
        node = parse(:tLiteral, "cast(100.00 as character varying(8))")
        node = parse(:tLiteral, "cast( 100.00 as character varying (8) )")
      end

      it "can be a ::cast on a string" do
        node = parse(:tLiteral, "'100'::int")
        node = parse(:tLiteral, "'100' :: int")
      end

      it "can be a ::cast on a number" do
        node = parse(:tLiteral, '100 :: varchar')
        node = parse(:tLiteral, '100::varchar')
      end
    end

  end
end
