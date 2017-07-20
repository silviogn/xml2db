# Models a group of attributes with their potential primary keys
class Relation
  @@relation_id_sequence = 0

  # Attributes for maintaining the attribute tree structure
  #
  attr_accessor :attributes, :parent, :depth, :tree, :attribute_maps
  attr_reader :pks, :id

  # Metadata attributes for relation designer
  #
  attr_accessor :rd_start_new              # does this get materialized as a new
                                           # relation?

  attr_accessor :rd_output_parent          # which relation does this ultimately
                                           # merge w/ in the final output

  attr_accessor :rd_prev_card,             # card of node above
                :rd_card,                  # card of this node
                :rd_card_start_new         # did card change cause start new?

  CLONE_ATTRS = [:parent,
                 :depth,
                 :rd_start_new, :attribute_maps,
                 :rd_output_parent,
                 :rd_prev_card,
                 :rd_card,
                 :rd_card_start_new
  ]

  def self.next_id
    orig = @@relation_id_sequence
    @@relation_id_sequence += 1
    orig
  end

  def initialize(pks, attributes, tree, id = nil)
    if id
      @id = id
    else
      @id = self.class.next_id
    end

    # Attributes for maintaining the attribute tree structure
    #
    @pks = pks.sort
    @attributes = (pks + attributes).uniq.sort
    @tree = tree

    # Metadata attributes for relation designer
    #
    @rd_start_new = false

    # Maintain an array mapping attributes from the original data set
    # to the physical attributes from the @attributes array
    #
    # Initialize to mapping every key in @attributes to itself
    @initial_map = Hash.new
    rebuild_initial_map
    @attribute_maps = [@initial_map]
  end

  def name
    "Relation#{@id}"
  end

  def has_pk?(field)
    @pks.include?(field)
  end

  def has_attr?(field)
    @attributes.include?(field)
  end

  def closure
    @tree.closure(@pks.first)
  end

  # Sets up the hash @initial_map so that every attribute in the relation
  # points to itself
  def rebuild_initial_map
    @attributes.each { |attr| @initial_map[attr] = attr }
  end

  # Is self a descendant of other?
  def descendant_of?(other)
    if other.id == id
      false
    else
      @tree.descendant_of?(other.pks.first, self.pks.first)
    end
  end

  def descendant_of_or_equal?(other)
    descendant_of?(other) || other.id == id
  end

  def children
    children = []
    (attributes - pks).each do |attribute|
      rel = tree.pk_to_relation(attribute)
      children << rel unless rel.nil?
    end
    children.uniq
  end

  def size
    closure.size
  end

  def add_attributes(attrs)
    @attributes.concat(attrs)
  end

  def remove_attributes(attrs)
    @pks = @pks - attrs
    @attributes = @attributes - attrs
  end

  def clone
    attrs = self.attributes.clone
    pks = self.pks.clone

    Relation.new(pks, attrs, tree, @id).tap do |r|
      CLONE_ATTRS.each do  |attr|
        r.send("#{attr}=".to_sym, self.send(attr))
      end
    end
  end

  # Add a new mapping from the original data set's attributes to the physical
  # attributes contained within the relation
  #
  # Validate that the map refers only to physical attribtues that actually exist
  def add_attribute_map(proposed_map)
    proposed_physical_values = []
    proposed_map.each do |k, v|
      proposed_physical_values << v unless k == :ORIGIN
    end

    if !(proposed_physical_values - attributes - pks).empty?
      raise "Cannot add an attribute map that references a non-existent attr:" \
            "#{proposed_physical_values - attributes - pks}"
    elsif proposed_map.values.uniq.length != proposed_map.values.length
      raise "Cannot duplicate a key from the attributes array"
    else
      attribute_maps << proposed_map
    end
  end

  # Remove a mapping from the original data set's attributes to physical
  # attributes contained within the relation
  #
  # Raise an exception if no deletion is possible
  def delete_attribute_map(target_map)
    initial_length = @attribute_maps.length
    @attribute_maps.delete_if { |map| map == target_map }
    final_length = @attribute_maps.length

    if initial_length == final_length
      raise "Attempt to remove non-existent map"
    end
  end

  def root?
    parent.nil?
  end

  # Return a SQL fragment that returns the cardinality of the current
  # relation in the active database.
  #
  # Uses @attribute_map to determine which of the attributes of the original
  # data set are relevant and how they should be interpreted
  def cardinality_query
    if root?
      return "SELECT count(*) as result FROM #{CONFIG[:tbl_name]};"
    end

    fragments = Array.new
    pk = pks.first
    attribute_maps.each do |attribute_map|
      attribute_map = attribute_map.invert    # now maps from INSTANCE -> DB
      next if attribute_map[pk].nil? || attribute_map[pk].strip.length == 0

      fragments << "SELECT DISTINCT #{attribute_map[pk]} FROM #{CONFIG[:tbl_name]}"
    end

    # Union applies the distinct operation for us
    "SELECT count(*) as result FROM (#{fragments.join(" UNION ")}) as r;"
  end

  # returns the name of this relation's unique table (e.g. a materialized
  # view in postgres that contains the unique tuples of this table)
  def unique_table_name
    "#{name}_unique"
  end
end
