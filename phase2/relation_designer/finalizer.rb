# Takes an attribute tree that has been annotated by one or more stages of the
# relation designer and produces a schema from it.
#
# Right now, this just prints out where the breaks are. In the future, this will
# need to produce code/scripts/something to actually create the tables and
# transform data into the appropriate format
module RelationDesigner
  class Finalizer

    attr_reader :attribute_tree

    def initialize(attribute_tree)
      @attribute_tree = attribute_tree
    end

    def print_schema
      # In addition to printing the schema, encode it as a YAML data structure
      # that can be processed to transform the input data into this shcema
      yml_array = []

      populate_output_parents
      sorted_output_parents.each do |output_parent|
        yml_array << (yml_relation = { pks: output_parent.pks, attr_maps: [] })
        puts "\n\nNew relation: #{output_parent.pks}"

        potential_parent = output_parent.parent
        potential_fk_to = potential_parent ? potential_parent.rd_output_parent : nil
        if potential_fk_to
          puts "FK back to: #{potential_fk_to.pks}"
          yml_relation[:potential_fk] = potential_fk_to.pks
        end

        puts "Cardinality start new?: #{output_parent.rd_card_start_new}"
        puts "Cardinality prev: #{output_parent.rd_prev_card}"
        puts "Cardinality curr: #{output_parent.rd_card}"

        puts "Attribute maps"
        maps = child_index[output_parent].map(&:attribute_maps).flatten
        maps.group_by { |m| m[:ORIGIN] }.each do |gname, gmaps|
          puts "Map from #{gname}"
          map = Hash.new
          gmaps.each { |gmap| map.merge!(gmap) }
          puts map
          yml_relation[:attr_maps] << map
        end
      end

      File.write("schema.yml", YAML.dump(yml_array))
    end

    # Based on the rd_start_new flags add a link from each relation to its
    # parent in the final output (its nearest ancestor with rd_start_new set)
    def populate_output_parents
      attribute_tree.relations.each { |r| r.rd_start_new = true if r.root? }

      attribute_tree.breadth_first_traversal do |rel|
        if rel.rd_start_new || rel.root?
          puts "self parent for #{rel.pks} (#{rel.object_id})"
          rel.rd_output_parent = rel
        else
          rel.rd_output_parent = rel.parent.rd_output_parent
          if rel.rd_output_parent.nil?
          end
          puts "parent of #{rel.pks} is #{rel.rd_output_parent.pks}"
        end
      end

      self
    end

    # Produce a list of all relations marked with rd_start_new sorted by
    # depth in the tree ASC
    def sorted_output_parents
      output_parents.sort_by(&:depth)
    end

    # Maps parent_rel => [ array of children ]
    def child_index
      unless @child_index
        @child_index = index = Hash.new { |h, k| h[k] = Array.new }

        attribute_tree.relations.each do |rel|
          index[rel.rd_output_parent] << rel
        end

        index
      end

      @child_index
    end

    def output_parents
      attribute_tree.relations.select { |r| r.rd_start_new }
    end
  end
end
