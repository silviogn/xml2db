# A RelationDesigner stage that introduces breaks based on the cardinality of
# the relations
module RelationDesigner
  class CardinalityStage < StageBase

    START_NEW_RATIO = 0.5

    def apply_transform(tree)
      tree.root.rd_start_new = true

      root_cardinality = metadata.get_cardinality(tree.root)
      mark_new(root_cardinality, [tree.root])
    end

    # Mark nodes which should begin a new materialized relation and recurse
    # on their descendants
    def mark_new(current_parent_cardinality, nodes)
      nodes.each do |node|
        node_cardinality = metadata.get_cardinality(node)

        # Record cardinality numbers
        node.rd_prev_card = current_parent_cardinality
        node.rd_card = node_cardinality

        # Mark where cardinality shifts cause changes
        if start_new?(current_parent_cardinality, node_cardinality)
          node.rd_start_new = true
          node.rd_card_start_new = true
        else
          node.rd_card_start_new = false
        end

        # Update the current cardinality and keep walking
        if node.rd_start_new
          next_cardinality = node_cardinality
        else
          next_cardinality = current_parent_cardinality
        end

        mark_new(next_cardinality, node.children)
      end
    end

    # Predicate that specifies whether a new relation should be started
    # as a result of the change from parent_cardinality to child_cardinality
    def start_new?(parent_cardinality, child_cardinality)
      ratio = child_cardinality.to_f / parent_cardinality.to_f
      ratio <= START_NEW_RATIO
    end
  end
end
