# These combine all of the PK matches (just class Match) into a single element
#
# Holds all of the matches invovled in R1 -> R2
class RelationPair
  attr_reader :live_matches, :dead_matches, :r1, :r2, :matches

  # Don't allow one pair to shadow another if the PK size increases
  # by at least SHADOW_THRESHOLD
  SHADOW_THRESHOLD = 0.5

  def initialize(r1, r2, matches)
    @r1, @r2 = r1, r2
    @dead_matches = Array.new
    @live_matches = Array.new
    self.matches = matches
  end

  # Binds a list of matches (at the pk-level) into the relation match,
  # partitioning them based on whether they're alive
  def matches=(matches)
    @matches = matches
    @dead_matches, @live_matches = matches.partition(&:has_fatal_annotation?)
  end

  def print
    puts "R1: #{r1.name}\t(#{r1.pks})"
    puts "R2: #{r2.name}\t(#{r2.pks})"
    puts "Candidate matches" unless live_matches.empty?
    live_matches.each(&:print)
  end

  # Returns the match with the largest join set size -- serves
  # as the representative of the relation pair
  def max_live_match
    @live_matches.sort_by { |m| m.n_matches }.last
  end

  # Returns ture if self can validly shadow/hide other_pair (because other
  # pair offers no new information)
  def can_shadow?(other_pair)
    my_max = max_live_match
    other_max = other_pair.max_live_match

    my_pk_card = my_max.attribute_matrix[other_max.e1][other_max.e2] || 0
    other_pk_card = other_max.n_matches

    diff = (my_pk_card - other_pk_card).abs
    ratio = diff.to_f / my_pk_card

    ratio <= SHADOW_THRESHOLD
  end

  def max_depth
    [r1.depth, r2.depth].max
  end

  # Returns the smaller of r1, r2
  def smaller_relation
    [r1, r2].sort_by(&:size).first
  end

  # Returns the larger of r1, r2
  def larger_relation
    ([r1, r2] - [smaller_relation]).first
  end

  # Returns true if (self.c1 descends from other c1  && self.c1 descends from
  # other c2) || (self.c1 descends from c2 && self.c2 descends from other c1)
  def descendant_of?(other)
    (r1.descendant_of?(other.r1) && r2.descendant_of?(other.r2)) ||
    (r1.descendant_of?(other.r2) && r2.descendant_of?(other.r1))
  end

  # Similar to #descendant_of? but allows relation equality as well
  def descendant_of_or_equal?(other)
    (
      r1.descendant_of_or_equal?(other.r1) &&
      r2.descendant_of_or_equal?(other.r2)
    ) ||
    (
      r1.descendant_of_or_equal?(other.r2) &&
      r2.descendant_of_or_equal?(other.r1)
    )
  end
end
