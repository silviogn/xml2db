# A MergedRelationship provides an interface to a group of nodes that
# have been smooshed together.
#
# Merged nodes have different names (their C1s and C2s are concatenated lists
# of attributes, instead of attributes that actually appear in the dataset).
# The strength and other stats about the merged relationship are delegated
# to the passed in relationship.
class MergedRelationship
  attr_reader :c1, :c2, :rel

  # c1 and c2 are the names that should be displayed, rel is what should
  # be delegated to
  def initialize(c1, c2, rel)
    if c1.is_a?(Array)
      @c1 = c1.flatten.join(", ")
    else
      @c1 = c1
    end

    if c2.is_a?(Array)
      @c2 = c2.flatten.join(", ")
    else
      @c2 = c2
    end

    @rel = rel
  end

  def method_missing(m, *args)
    @rel.send(m, *args)
  end
end
