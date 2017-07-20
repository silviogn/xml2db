require "rgl/adjacency"
require "rgl/transitivity"
require "rgl/connected_components"
require "rgl/topsort"
require "relationship_manager"

class RelationshipGraph
  attr_reader :all_columns, :graph

  def initialize
    @all_columns = Set.new
    @rels = Hash.new { |h, k| h[k] = Hash.new }             # col -> col -> rel
    @graph = RGL::DirectedAdjacencyGraph.new
    @merged_columns = Set.new                       # names of collapsed nodes
    @relationship_manager = RelationshipManager.new
  end

  # Collapses nodes together if they have a circular relationship
  def merge_nodes
    # Map original column name to a set of merged names
    column_map = Hash.new { |h, k| h[k] = Set.new }
    pairs = bidirectional_relationships
    pairs.each do |pair|
      merged = column_map[pair.first]
      merged.merge(pair)
      merged.merge(column_map[pair.last])
      column_map[pair.last] = merged
    end

    # Materialize the merged groups into actual nodes in the graph
    seen = Set.new
    column_map.values.each do |group|
      group = group.to_a.sort
      next if seen.include?(group)
      seen << group

      descendants = Set.new
      parents = Set.new
      group.each do |member|
        descendants += @graph.adjacent_vertices(member)
        parents += get_incoming_relationships(member).map(&:c1)
      end

      descendants -= group
      parents -= group
      merged_name = @relationship_manager.merge_nodes(group)

      @graph.add_vertex(merged_name)
      @merged_columns += group

      # Update links in/out
      descendants.each do |descendant|
        rel = @relationship_manager.make_merged_relationship(group, descendant)
        add_relationship(rel)
      end
      parents.each do |parent|
        rel = @relationship_manager.make_merged_relationship(parent, group)
        add_relationship(rel)
      end
    end

    pairs.flatten.uniq.each do |node|
      @graph.remove_vertex(node)
    end
  end

  def merged_columns
    @merged_columns.to_a
  end

  # If two columns point at each other, the edge with the lower cardinality
  # is removed from the graph (must run after merge nodes to have any
  # chance at merging)
  def break_cycles
    @graph.each_vertex do |c1|
      c1_neighbors = @graph.adjacent_vertices(c1)
      c1_neighbors.each do |c2|
        next if !@graph.has_edge?(c2, c1)

        c1_out = @graph.adjacent_vertices(c1).length
        c2_out = @graph.adjacent_vertices(c2).length
        if c1_out <= c2_out
          @graph.remove_edge(c1, c2)
        end
      end
    end
  end

  # Returns all relationships that point in both directions and have exactly
  # the same descendants
  def bidirectional_relationships
   bidirectional = Set.new
   @graph.each_vertex do |c1|
      c1_neighbors = @graph.adjacent_vertices(c1)
      c1_neighbors.each do |c2|
        next if !@graph.has_edge?(c2, c1)

        # Compute number of overlapping descendants
        c2_neighbors = @graph.adjacent_vertices(c2)
        n_c1 = c1_neighbors.length - 1    # remove c2
        n_c2 = c2_neighbors.length - 1    # remove c1
        n_total =  (c1_neighbors & c2_neighbors).length

        if  n_c1 == n_c2 && n_c2 == n_total
          pair_name = [c1, c2].sort
          bidirectional << pair_name
        else
           puts "#{c1} <-> #{c2} but not perfectly"
        end
      end
    end

    bidirectional.to_a
  end

  # Returns relationships of the form X -> c2
  def get_incoming_relationships(c2)
    incoming = []

    @graph.each_vertex do |c1|
      next if c1 == c2

      if @graph.has_edge?(c1, c2)
        incoming << @relationship_manager.get_relationship(c1, c2)
      end
    end

    incoming
  end

  # Returns relatinoships of the form col -> X
  def get_outgoing_relationships(c1)
    @graph.adjacent_vertices(c1).map do |c2|
      @relationship_manager.get_relationship(c1, c2)
    end
  end

  # Adds a relationship to the graph (each column becomes a node in the
  # graph)
  def add_relationship(relationship)
    @relationship_manager.add_relationship(relationship)
    @graph.add_edge(relationship.c1, relationship.c2)
  end

  # Asks the relationship manager for the rel between two nodes
  # mostly for testing
  def get_relationship(a, b)
    @relationship_manager.get_relationship(a, b)
  end

  # Detects cycles within the graph
  def has_cycle?
    !@graph.acyclic?
  end

  def compute_longest_paths
    return if @longest_paths_computed

    @longest_paths_computed = true
    @longest_path = Hash.new

    if has_cycle?
      raise(
        NotImplementedError,
        "The relationship graph has cycles and requires a brute force search " \
        "for longest paths. This has not been implemented yet."
      )
    else
      puts "Quick longest paths operating"
      quick_compute_longest_paths
    end
  end

  # Computes the longest path from ROOT to every other node x. Also records
  # the the node y such that the last edge on the path is (y, x)
  def quick_compute_longest_paths
    # for all u such that (u, v), maps v -> [u]
    incoming_edges = Hash.new { |h, k| h[k] = Array.new }
    @graph.each_edge { |u, v| incoming_edges[v] << u }

    # Topsort guarantees that if there's an edge from (u, v), v will be
    # in the list after u
    @graph.topsort_iterator.to_a.each do |v|
      if incoming_edges[v].length == 0
        @longest_path[v] = [TableGenerator::ROOT_NAME]
        next
      end

      # examine all incoming edges and choose the longest one as the predecessor
      # resolve ties by choosing the stronger match
      predecessor = []
      predecessor_rel = nil

      incoming_edges[v].each do |u|
        incoming_rel = @relationship_manager.get_relationship(u, v)
        if (@longest_path[u].length > predecessor.length) ||
           (@longest_path[u].length == predecessor.length &&
            (predecessor_rel.nil? ||
            incoming_rel.strength > predecessor_rel.strength))
          predecessor = @longest_path[u]
          predecessor_rel = incoming_rel
        end
      end

      @longest_path[v] = ([*predecessor.dup, v])
    end
  end

  # returns the longest path ending at x
  def get_longest_path_length(x)
    compute_longest_paths
    @longest_path[x].length - 1
  end

  # returns the node y such that the last edge on the longest path from the
  # root is (y, x)
  def get_longest_path_predecessor(x)
    compute_longest_paths
    @longest_path[x][-2]
  end
end
