# frozen_string_literal: true

class Monoid
  attr_accessor :alphabet, :rules

  def initialize(alphabet, rules)
    @alphabet = alphabet
    @rules = rules
  end

  # Apply each rule in arbitrary order until fixpoint
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

  # Make sure we go from more -> less
  def orient_rule!(rule)
    if less_than(rule[0], rule[1])
      rule[0], rule[1] = rule[1], rule[0]
    end
    rule
  end

  # Orient in-place and add new rule (if it's not a -> a)
  # Return true if we added a rule and false otherwise
  def add_rule!(rule)
    rule = [reduce(rule[0].dup), reduce(rule[1].dup)]
    if rule[0] != rule[1]
      rules << orient_rule!(rule)
      true
    else
      false
    end
  end

  def string_upto(s, idx)
    if idx < 0
      ""
    else
      s[..idx]
    end
  end

  def handle_overlap(x, y, overlap)
    x_left, x_right = x
    y_left, y_right = y
    if overlap + y_left.length <= x_left.length
      # the overlap is fully contained in x's lhs
      # x: bbabbbb -> U
      # y: bab -> V
      # b bab bbb
      #   bab
      # (U, b V bbb)
      [x_right, string_upto(x_left, overlap-1) + y_right + x_left[overlap+y_left.length..]]
    else
      # x: bbbbba -> U
      # y: bab -> V
      # bbbb ba
      #      ba b
      # (U b, bbbb V)
      [x_right + y_left[x_left.length-overlap..], string_upto(x_left, overlap-1)+y_right]
    end
  end

  def resolve_overlaps
    to_add = []
    rules.each do |x|
      rules.each do |y|
        x_left = x[0]
        y_left = y[0]
        find_overlaps(x_left, y_left).each do |overlap|
          critical_pair = handle_overlap(x, y, overlap)
          to_add << critical_pair
        end
      end
    end
    to_add.each do |rule|
      add_rule!(rule)
    end
  end
end

# Find out all the indices (in the left string) where some prefix of right
# matches a suffix of left
def find_overlaps(left, right)
  result = []
  0.upto(left.length-1).each do |i|
    left_substring = left[i..]
    smaller, bigger = if left_substring.length < right.length
                        [left_substring, right]
                      else
                        [right, left_substring]
                      end
    if bigger.start_with?(smaller)
      result << i
    end
  end
  result
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

  def test_add_rule_reduces_rules
    m = Monoid.new("abc", [])
    m.add_rule!(["ab", ""])
    m.add_rule!(["aaabbb", ""])
    assert_equal([["ab", ""]], m.rules)
  end

  def test_critical_pair_at_beginning
    m = Monoid.new("ab", [])
    left = ["bbbb", "U"]
    right = ["bbbb", "V"]
    result = m.handle_overlap(left, right, 0)
    assert_equal(["U", "V"], result)
  end

  def test_critical_pair_contained
    m = Monoid.new("ab", [])
    left = ["bbabbbb", "U"]
    right = ["bab", "V"]
    overlaps = find_overlaps(left.first, right.first)
    assert_equal([1, 6], overlaps)
    result = m.handle_overlap(left, right, overlaps[0])
    assert_equal(["U", "bVbbb"], result)
  end

  def test_critical_pair_at_end
    m = Monoid.new("ab", [])
    left = ["bbbbba", "U"]
    right = ["bab", "V"]
    overlaps = find_overlaps(left.first, right.first)
    assert_equal([4], overlaps)
    result = m.handle_overlap(left, right, overlaps[0])
    assert_equal(["Ub", "bbbbV"], result)
  end

  def test_resolve_overlaps
    rules = [["ab", "a"], ["bc", "b"]]
    m = Monoid.new("abc", rules.dup)
    m.resolve_overlaps
    assert_equal(rules + [["ac", "a"]], m.rules)
  end

  def test_resolve_overlaps2
    rules = [["bbbb", "aaaa"]]
    m = Monoid.new("ab", rules.dup)
    overlaps = find_overlaps(rules.first.first, rules.first.first)
    assert_equal([0, 1, 2, 3], overlaps)
    m.resolve_overlaps
    assert_equal(rules + [["baaaa", "aaaab"]], m.rules)
  end
end

class FindOverlapsTests < Minitest::Test
  def test_overlap_right_smaller
    assert_equal([0, 3], find_overlaps("abca", "a"))
  end

  def test_overlap_left_smaller
    assert_equal([0], find_overlaps("a", "abca"))
  end

  def test_no_overlap
    assert_equal([], find_overlaps("a", "d"))
  end

  def test_contained
    assert_equal([1], find_overlaps("abba", "bb"))
  end

  def test_slava
    assert_equal([4, 5], find_overlaps("aababb", "bba"))
  end
end
