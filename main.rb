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
        changed ||= string.sub!(rule[0], rule[1])
      end
    end
    string
  end
end

require "minitest/autorun"

class MonoidTests < Minitest::Test
  def test_reduce_one_rule
    m = Monoid.new("ab", [["ab", ""]])
    assert_equal("", m.reduce(+"ab"))
    assert_equal("a", m.reduce(+"a"))
    assert_equal("", m.reduce(+"aaaabbbb"))
    assert_equal("bb", m.reduce(+"aaaabbbbbb"))
  end

  def test_reduce_multiple_rules
    m = Monoid.new("abc", [["ab", "a"], ["bc", "b"], ["ac", "a"]])
    assert_equal("ba", m.reduce(+"babbbccc"))
  end
end
