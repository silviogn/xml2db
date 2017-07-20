# An abstract class that represents one stage in the RelationDesigner. Accepts
# an attribute tree as an input and performs some transformation of the tree
module RelationDesigner
  class StageBase

    # Initialize with the input tree and an object which tracks the gathered
    # metadata
    def initialize(attribute_tree, metadata)
      @metadata = metadata
      @attribute_tree = attribute_tree
    end

    # Returns a new attribute tree with the appropriate transformation applied
    def transformed_attribute_tree
      attribute_tree.clone.tap do |cloned_tree|
        apply_transform(cloned_tree)
      end
    end

    private
    def metadata
      @metadata
    end

    def attribute_tree
      @attribute_tree
    end

    # Subclasses should implement this method so that their transformations
    # can be carried out
    def apply_transform(tree)
      raise "Abstract method called"
    end
  end
end
