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

  # shortlex
  # Return true iff left strictly smaller than right
  # Return false if left length >= right length or left lexically equal to or
  # greater than right
  def less_than(left, right)
    if left.length < right.length
      true
    elsif left.length > right.length
      false
    else
      left < right
    end
  end

  def orient_rule!(rule)
    if less_than(rule[0], rule[1])
      rule[0], rule[1] = rule[1], rule[0]
    end
    rule
  end

  def add_rule!(rule)
    if rule[0] != rule[1]
      rules << orient_rule!(rule)
    end
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

  def test_orient_rule_swaps_length
    m = Monoid.new("abc", [])
    rule = ["a", "ab"]
    m.orient_rule!(rule)
    assert_equal(["ab", "a"], rule)
  end

  def test_orient_rule_does_not_swap_length
    m = Monoid.new("abc", [])
    rule = ["ab", "a"]
    m.orient_rule!(rule)
    assert_equal(["ab", "a"], rule)
  end

  def test_orient_rule_swaps_lexicographic_order
    m = Monoid.new("abc", [])
    rule = ["a", "b"]
    m.orient_rule!(rule)
    assert_equal(["b", "a"], rule)
  end

  def test_orient_rule_does_not_swap_lexicographic_order
    m = Monoid.new("abc", [])
    rule = ["b", "a"]
    m.orient_rule!(rule)
    assert_equal(["b", "a"], rule)
  end

  def test_add_rule_orients_rule
    m = Monoid.new("abc", [])
    m.add_rule!(["a", "ab"])
    assert_equal(["ab", "a"], m.rules[0])
  end

  def test_add_equal_does_not_add
    m = Monoid.new("abc", [])
    m.add_rule!(["a", "a"])
    assert_equal([], m.rules)
  end
end
