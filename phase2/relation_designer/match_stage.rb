# The match stage of the RelationDesigner modifies the attribute tree to account
# for nodes that should be merged together as a result of data identified
# in phase two
module RelationDesigner
  class MatchStage < StageBase

    def apply_transform(tree)
      merge_groups = sort_grouped_relations(grouped_relations)
      puts "merging order:"
      merge_groups.each { |group| merge_group(group, tree) }
    end

    # Return groups of relations that should be merged into one
    #
    # Groups of relations that are individually paired with one another
    # are merged together here. An exception is raised if the merging
    # doesn't reflect the transitive patterns we'd expect.
    def grouped_relations
      return @grouped_relations if @grouped_relations

      @grouped_relations = Array.new

      # Validate that transitive pairings exist everywhere
      pairs.each do |pair|
        expected_pairings = pair_index[pair.r1]   # all things paired w/ r1

        expected_pairings = expected_pairings - [pair.r2]  # don't expect r2
        expected_pairings << pair.r1                       # expect r1

        unless expected_pairings == pair_index[pair.r2]
          raise "Transitive pairing missing"
        end
      end

      # Populate the grouped_relations hash
      seen = Set.new
      attribute_tree.relations.each do |r|
        next if seen.include?(r)
        next if pair_index[r].empty?

        relations = pair_index[r].to_a
        relations << r

        seen += relations

        @grouped_relations << relations
      end

      @grouped_relations
    end

    # Accessor for an array of RelationPairs
    def pairs
      metadata.pairs
    end

    # A map from relations to a set of all relations it's paired with
    def pair_index
      unless @pair_index
        @pair_index = Hash.new { |h, k| h[k] = Set.new }
        pairs.each do |pair|
          @pair_index[pair.r1] << pair.r2
          @pair_index[pair.r2] << pair.r1
        end
      end

      @pair_index
    end

    # Return groups in order of decreasing maximum depth
    def sort_grouped_relations(groups)
      return groups.sort_by do |group|
        -1 * group.map(&:depth).max
      end
    end

    def global_attribute_map
      unless @global_attribute_map
        @global_attribute_map = Hash.new
        attribute_tree.root.closure.each do |a|
          @global_attribute_map[a] = Set.new
          @global_attribute_map[a] << a
        end
      end

      @global_attribute_map
    end

    # Takes a group of relations and merges their attribute tree nodes into
    # a single relation object in the tree
    def merge_group(group, tree)
      # select the relation with the largest closure to be the canoncial one
      #
      canonical_rel = group.max_by { |rel| rel.closure.length }
      canonical_rel = tree.id_to_relation(canonical_rel.id)

      puts "merging #{group.map(&:pks).flatten.join(" ")}"
      puts "canoncial rel #{canonical_rel.pks}"

      group.each do |other_rel|
        other_rel = tree.id_to_relation(other_rel.id)
        next if other_rel == canonical_rel
        pair = pairs.detect do |p|
          (p.r1.id == canonical_rel.id && p.r2.id == other_rel.id) ||
          (p.r2.id == canonical_rel.id && p.r1.id == other_rel.id)
        end

        group_id = [*canonical_rel.pks, *other_rel.pks].join(" ")


        # extract the matching information
        match = pair.live_matches.max_by { |m| m.n_matches }
        matrix = nil
        attribute = ([match.e1, match.e2] & other_rel.pks).first
        match.with_e1_as(attribute) do |m|
          matrix = m.maximum_accepted_attribute_matrix
        end

        # Maps relation -> the mapping for that relation
        mappings = Hash.new { |h, k| h[k] = { ORIGIN: group_id} }
        missing = Array.new    # values that didn't map
        mapped_attributes = Array.new # store mapped attrs that have been used

        remerged_trees = Array.new    # trees that already have mappings
        seen_remerged_pks = Set.new   # for split attrs
        mappable_attributes = Array.new # attrs in other_rel.closure that are
                                        # not in any remerged tree

        # find the attrs that can be mapped & remerge attempts
        #
        # if an attribute is a PK of a relation that has already been
        # marked as start new, then that lower relation has already been
        # merged. we want to exclude all of those accounted for attrs from
        # this merging higher in the tree
        mappable_attributes = other_rel.closure.clone
        other_rel.closure.each do |attribute|
          next if seen_remerged_pks.include?(attribute)

          potential_nested_rel = tree.pk_to_relation(attribute)
          next if potential_nested_rel.nil?

          next unless potential_nested_rel.rd_start_new

          remerged_trees << potential_nested_rel
          seen_remerged_pks.merge(potential_nested_rel.pks)
          mappable_attributes -= potential_nested_rel.closure
        end

        # create mappings for the new attributes that haven't been merged
        # at another point in the tree
        mappable_attributes.each do |attribute|
          # Record missing attributes
          unless matrix.key?(attribute)
            missing << attribute
            next
          end

          # Chose an attribute to map to
          potential_mappings = matrix[attribute].keys
          mapped_attr = (potential_mappings - mapped_attributes).first
          # Chose an attribute to map to
          if mapped_attr.nil?
            missing << attribute
            next
          end

          mapped_attributes << mapped_attr
          global_attribute_map[attribute] << mapped_attr
          rels = [canonical_rel]
          until (rel = rels.pop).nil?
            if rel.attributes.include?(mapped_attr)
              mappings[rel][attribute] = mapped_attr
            end
            rels += rel.children
          end

        end

        # remove canoncial attribute map entries for merged nodes
        #
        # Canoncial attribute tree
        remerged_trees.each do |remerged_tree|
          canonical_rel.attribute_maps.each do |can_attribute_map|
            merged_trees = [remerged_tree]
            until (merged_tree = merged_trees.pop).nil?
              merged_tree.attribute_maps.each do |m_attribute_map|
                 m_attribute_map.keys.each { |mk| can_attribute_map.delete(mk) }
              end

              merged_trees += merged_tree.children
            end
          end
        end

        # move remerged branches to their new home (they move to children
        # of a branch in canoncial

        # only worry about the highest one if they're nested
        remerged_must_move = Array.new
        remerged_trees.sort_by!(&:depth)
        remerged_trees.each_with_index do |remerged_tree, idx|
          must_move = true
          (0...idx).each do |later_idx|
             must_move = false if remerged_tree.descendant_of?(remerged_trees[later_idx])
          end
          remerged_must_move << remerged_tree if must_move
        end

        # Actually do the moving now.
        remerged_must_move.each do |remerged_tree|
          # step 1, find the attrs the pks map to
          pk_possibilities = Array.new
          remerged_tree.attribute_maps.each do |attribute_map|
            inverted_map = attribute_map.invert
            remerged_tree.pks.each { |pk| pk_possibilities << inverted_map[pk] }
          end
          pk_possibilities -= remerged_tree.pks
          pk_possibilities = pk_possibilities.map do |a|
            global_attribute_map[a].to_a
          end.flatten

          # step 2, find parent in new branch
          potential_parents = [canonical_rel]
          until (potential_parent = potential_parents.pop).nil?
            break if !(potential_parent.attributes & pk_possibilities).empty?
            potential_parents += potential_parent.children
          end

          byebug if potential_parent.nil?

          # step 3, replace pk_possibilities in new parent with new pks

          # prevent the remerged tree from being deleted
          remerged_tree.parent.remove_attributes(remerged_tree.pks)

          # get rid of the mapped attrs in the new parent
          potential_parent.remove_attributes(pk_possibilities)

          #  add the new PKs to the new parent and setup pointer
          potential_parent.add_attributes(remerged_tree.pks)

          # recalc depths etc
          tree.send(:initialize_relations)
          remerged_tree.parent = potential_parent
        end

        # Update the tree with the new mappings and removals
        canonical_rel.attributes.concat(missing)
        puts "Could not map #{missing} to any canonical attribute"
        missing.each do |attribute|
          mappings[canonical_rel][attribute] = attribute
        end
        mappings.each do |relation, mapping|
          relation.add_attribute_map(mapping)
        end
        canonical_rel.rd_start_new = true
        tree.delete_relation(other_rel)
      end
    end
  end
end
