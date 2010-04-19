require 'rubygems'
require 'spec'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'piggly'))

#Dir[File.join(File.dirname(__FILE__), 'mocks', '*')].each do |m|
#  require File.expand_path(m)
#end

module Piggly
  module GrammarHelper

    COMMENTS = ["abc defghi", "abc -- abc", "quote's", "a 'str'"]

    SQLWORDS = %w[select insert update delete drop alter
                  commit begin rollback set start vacuum]

    KEYWORDS = %w[as := = alias begin by close constant continue
                  cursor debug declare diagnostics else elsif elseif
                  end exception execute exit fetch for from get if
                  in info insert into is log loop move not notice
                  null open or perform raise rename result_oid return
                  reverse row_count scroll strict then to type warning
                  when while]

    def parse(root, input)
      string = input.downcase
      parser = Parser.parser
      parser.root = root
      parser.consume_all_input = true
      parser.parse(string) or raise Parser::Failure, parser.failure_reason
    ensure
      string.replace input
    end

    def parse_some(root, input)
      string = input.downcase
      parser = Parser.parser
      parser.root = root
      parser.consume_all_input = false
      node = parser.parse(string)
      raise Parser::Failure, parser.failure_reason unless node
      return node, input[parser.index..-1]
    ensure
      string.replace input
    end
  end
end

module Enumerable
  def test_each
    each do |o|
      begin
        yield o
      rescue
        $!.message << "; while evaluating #{o}"
        raise
      end
    end
  end
end
