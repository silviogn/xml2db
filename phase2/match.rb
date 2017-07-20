# Models the results of a run joining the relation on e1 = e2
class Match
  ATTRIBUTES = [
    :e1,                     #relation one's name
    :e2,                     #relation two's name
    :n_matches,              #number of records where e1 = e2
    :attribute_matrix,       #maps [a1][a2] to a count of the number
                             #  of times val(a1) = val(a2)
    :duration,               # time required to compute match data
    :start,
    :end
  ]

  attr_accessor(*ATTRIBUTES)
  attr_reader :e1_attr_count_adjustment, :e2_attr_count_adjustment
  attr_accessor :match_annotations

  # Annotations that indicate that a match has been excluded from active
  # consideration -- will be printed separately
  FATAL_ANNOTATIONS = [:small_join, :pk_raw_klass_mismatch, :same_relation,
    :pk_clustered_klass_mismatch, :single_attr_match, :fatal_incomplete]

  # The level at which we consider a pairing of two attributes significant
  ATTRIBUTE_MATCH_THRESHOLD = 0.985

  def initialize
    # Create a 2D matrix where every bucket is initialized to 0
    @attribute_matrix = blank_attribute_matrix

    # Maps an annotation symbol to an array of messages
    @match_annotations = Hash.new { |h,k| h[k] = Array.new }

    # Maps a matrix entry to a hash of key --> messages
    @matrix_annotations = Hash.new do |h1, k1|
      h1[k1] = Hash.new do |h2, k2|
        h2[k2] = Hash.new { |h3, k3| h3[k3] = Array.new }
      end
    end

    # See the #remove_self_matches function
    @e1_attr_count_adjustment = 0
    @e2_attr_count_adjustment = 0
  end

  # Deserializes a Match instance from the provided string
  def self.deserialize(yaml)
    attrs = YAML.load(yaml)
    Match.new.tap do |match|
      ATTRIBUTES.each do |attr|
        match.send("#{attr}=".to_sym, attrs[attr])
      end
    end
  end

  # Produces a string that can be used to serialize a match object to YAML
  def serialize
    attrs = Hash.new
    ATTRIBUTES.each do |attr|
      attrs[attr] = self.send(attr)
    end

    YAML.dump(attrs)
  end

  # Allows the match to be associated with an attribute tree which can be used
  # in various computations
  def attribute_tree=(at)
    @attribute_tree = at
  end

  # Allows access to the attribute tree associated with the match
  def attribute_tree
    if @attribute_tree
      @attribute_tree
    else
      raise "Attribute tree must be set before use"
    end
  end

  # Setter to allow type catalog binding (should be refactored into the
  # initializer)
  def type_catalog=(tc)
    @type_catalog = tc
  end

  # Accessor to allow safe access to a potentially uninitialized type
  # catalog
  def type_catalog
    if @type_catalog
      @type_catalog
    else
      raise "Type catalog must be set before use"
    end
  end

  # Since we allow relations lower in the tree to match with their parents,
  # it's possible for the same attribute (e.g. the same field in the orig
  # relation) to appear  on both sides of the join. This type of self
  # matching is confusing and doesn't yeild anything very intersting, so
  # we eliminate it.
  #
  # Solution: always assume the overlapping attributes belong to the relation
  # that's deeper in the ancestral graph
  #
  # Record the number of these attributes present in the higher graph
  # so that we can make adjustments to the attribute count if deemed
  # necessary
  def remove_self_matches
    overlapping = attribute_tree.closure(e1) & attribute_tree.closure(e2)
    attr_count_adjustment = -1 * overlapping.length

    # E2 descends from E1 -- outer not allowed to use
    if attribute_tree.descendant_of?(e1, e2)
      overlapping.each { |bad_attr| attribute_matrix.delete(bad_attr) }
      @e1_attr_count_adjustment = attr_count_adjustment

    # e1 descends from e2 -- inner not allowed to use
    elsif attribute_tree.descendant_of?(e2, e1)
     attribute_matrix.each do |attr, inner_hash|
        overlapping.each { |bad_attr| inner_hash.delete(bad_attr) }
      end
      @e2_attr_count_adjustment = attr_count_adjustment
    end

    @normalized_attribute_matrix = nil
    @accepted_attribute_matrix = nil
  end

  def print
    puts "Match: #{e1} --> #{e2} \t\tsize: #{n_matches}"
    print_match_annotations
    MatrixFormatter.new(self).print
    puts "\n"
  end

  # Returns true if this match can be merged with other_match
  #
  # Merge decisions are made based on whether the matches have exactly
  # the same attribute matrix
  def merge?(other_match)
    mine = attribute_matrix
    theirs = other_match.attribute_matrix

    Helpers.deep_matrix_comparison(mine, theirs)
  end

  # This method prints the raw matrix from the match, with appropriate
  # formatting
  def print_raw_matrix
    raise NotImplemented
  end

  # Returns the relation with fewer attributes
  def smaller_relation
  end

  # Provides a hash of E1 attribute -> [list of matched E2 attributes]
  #
  # This method applies selection criteria to limit the number of matches
  # and ensure they're appropriately represent. It is not a raw representation
  # of the underlying matrix.
  def attribute_matches
    out = Hash.new

    attribute_matrix.each do |attribute, matches|
      maximum = matches.values.max
      maximum_normalized = maximum.to_f / n_matches

      out[attribute] = Hash.new

      if maximum_normalized <= 0.95
        next
      end

      matches.each do |match, value|
        out[attribute][match] = value  if value == maximum
      end

      out[attribute].sort
    end


    out
  end

  # Normalizes the values in the matrix by the number of matches in the
  # join set
  def normalized_attribute_matrix
    unless @normalized_attribute_matrix
      @normalized_attribute_matrix = blank_attribute_matrix

      attribute_matrix.each do |a1, inner_hash|
        inner_hash.each do |a2, value|
          @normalized_attribute_matrix[a1][a2] = value.to_f / n_matches
        end
      end

      @accepted_attribute_matrix = nil              # force refresh
      @maximum_accepted_attribute_matrix = nil      # force refresh
    end

    @normalized_attribute_matrix
  end

  # Reutrns an attribute matrix containing only attributes that have passed
  # all alginment criterion
  def accepted_attribute_matrix
    unless @accepted_attribute_matrix
      temp_normalized = normalized_attribute_matrix      #b/c the refresh is linked
      @accepted_attribute_matrix = blank_attribute_matrix

      temp_normalized.each do |attr1, inner_hash|
        inner_hash.each do |attr2, normalized_value|

          # Require a certain level of attribute matching to accept
          next unless normalized_value > ATTRIBUTE_MATCH_THRESHOLD

          # Require attributes to have the same clustered class
          ty1 = type_catalog.clustered_klass(attr1)
          ty2 = type_catalog.clustered_klass(attr2)
          next unless ty1 == ty2

          @accepted_attribute_matrix[attr1][attr2] = normalized_value
        end
      end
    end

    @accepted_attribute_matrix
  end

  # Returns an accepted attribute matrix, modified only to have the maximum
  # match for each attribute
  def maximum_accepted_attribute_matrix
    unless @maximum_accepted_attribute_matrix
       temp_normalized = accepted_attribute_matrix      #b/c the refresh is linked
      @maximum_accepted_attribute_matrix = blank_attribute_matrix

      temp_normalized.each do |attr1, inner_hash|
        maximum_value = inner_hash.values.max
        inner_hash.each do |attr2, normalized_value|
          next unless normalized_value == maximum_value

          @maximum_accepted_attribute_matrix[attr1][attr2] = normalized_value
        end
      end
    end

    @maximum_accepted_attribute_matrix
  end

  # Returns an attribute matrix that's properly initialized
  def blank_attribute_matrix
    Hash.new do |h, k|
      h[k] = Hash.new(0)
    end
  end

  # Adds an annotation to the match
  def annotate_match(key, message)
    @match_annotations[key] ||= Array.new
    @match_annotations[key] << message
  end

  def print_match_annotations(stream = $stdout)
    @match_annotations.each do |key, messages|
      messages.each do |message|
        stream.puts "#{key.to_s.upcase}: #{message}"
      end
    end
  end

  def has_match_annotation?(key)
    @match_annotations.key?(key)
  end

  def annotate_matrix(attr1, attr2, key, message)
    @matrix_annotations[attr1] ||= Hash.new
    @matrix_annotations[attr1][attr2] ||= Hash.new
    @matrix_annotations[attr1][attr2][key] ||= Array.new
    @matrix_annotations[attr1][attr2][key] << message
  end

  def has_matrix_annotation?(attr1, attr2, key)
    @matrix_annotations.key?(attr1) &&
    @matrix_annotations[attr1].key?(attr2) &&
    @matrix_annotations[attr1][attr2].key?(key)
  end

  # Returns true if the node has no parent
  def is_root?
    parent == nil
  end

  # Returns true if the match has any of the annotations listed in
  # Match::FATAL_ANNOTATIONS
  def has_fatal_annotation?
    included = Match::FATAL_ANNOTATIONS.map do |a|
      self.has_match_annotation?(a)
    end
    included.include?(true)
  end

  def get_matrix_annotations(attr1, attr2)
    if @matrix_annotations.key?(attr1) && @matrix_annotations[attr1].key?(attr2)
      @matrix_annotations[attr1][attr2]
    else
      {}
    end
  end

  # Ensures that the blk deals with the match in its proper orientation
  def with_e1_as(expected_e1, &blk)
    if blk.nil?                        #if no block provided, retrun the match
      blk = Proc.new { |a| a }
    end

    if e1 == expected_e1
      blk.call(self)
    elsif e2 == expected_e1
      blk.call(invert)
    else
      raise "Argument must be either e1 or e2"
    end
  end

  private
  # Constructs a new match that has e1=self.e2 and e2=self.e1
  def invert
    out = Match.new
    out.e1 = self.e2
    out.e2 = self.e1
    out.n_matches = self.n_matches
    out.type_catalog = type_catalog
    out.attribute_tree = attribute_tree
    out.match_annotations = @match_annotations

    attribute_matrix.each do |outer_key, inner_hash|
      inner_hash.each do |inner_key, value|
        out.attribute_matrix[inner_key][outer_key] = value
      end
    end

    out
  end
end
