# frozen_string_literal: true

class Monoid
  attr_accessor :alphabet, :rules

  def initialize(alphabet, rules)
    @alphabet = alphabet
    @rules = rules
  end

  def reduce(string)
    changed = true
    while changed
      changed = false
      for rule in rules
        changed |= string.sub!(rule[0], rule[1])
      end
    end
    string
  end
end

require "minitest/autorun"

class MonoidTests < Minitest::Test
  def test_reduce_one_rule
    thing = Monoid.new("ab", [["ab", ""]])
    assert_equal("", thing.reduce(+"ab"))
    assert_equal("a", thing.reduce(+"a"))
    assert_equal("", thing.reduce(+"aaaabbbb"))
    assert_equal("bb", thing.reduce(+"aaaabbbbbb"))
  end
end
