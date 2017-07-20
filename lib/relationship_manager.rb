require "byebug"
require "relationship"
require "merged_relationship"

# A relationship manager tracks relationships. It manages merging and
# serves as a factory for merged relationships
class RelationshipManager
  def initialize
    @rels = Hash.new { |h, k| h[k] = Hash.new }             # col -> col -> rel
    @merged_members = Hash.new                # merged_name -> [member names]
  end

  # Merges nodes together and returns their new name
  def merge_nodes(nodes)
    merged_name = nodes.join(", ")
    @merged_members[merged_name] = nodes
    merged_name
  end

  # Add relationship to the index
  def add_relationship(relationship)
    @rels[relationship.c1][relationship.c2] = relationship
  end

  def get_relationship(c1, c2)
    if @rels[c1][c2]
      @rels[c1][c2]
    else
      raise AssertionError, "Accessed missing relationship"
    end
  end

  # Used to create replacement edges in the graph once a node has been merged
  # together. Loops through all possible edges (relationships) and finds
  # the strongest one. This strongest relationship is then used to build
  # the merged relaitonship which is added to the manager and returned
  def make_merged_relationship(c1, c2)
    c1 = @merged_members[c1] || [c1].flatten
    c2 = @merged_members[c2] || [c2].flatten

    rel = nil
    c1.each do |c1_elt|
      c2.each do |c2_elt|
        candidate = get_relationship(c1_elt, c2_elt)
        rel ||= candidate

        if rel.strength <= candidate.strength
          rel = candidate
        end
      end
    end

    rel = MergedRelationship.new(c1, c2, rel)
    add_relationship(rel)
    rel
  end
end
