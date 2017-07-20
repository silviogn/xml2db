require "set"
require "yaml"

require "relationship"
require "relationship_graph"

class TableGenerator
  attr_accessor :graph
  ROOT_NAME = "ROOT"

  def initialize(dir_path)
    rels = Relationship.from_directory(dir_path)
    @graph = RelationshipGraph.new
    @all_columns = Set.new

    rels.each do |rel|
      @graph.add_relationship(rel) if add_relationship?(rel)
      @all_columns << rel.c1
      @all_columns << rel.c2
    end

    create_root_node
    preprocess_graph
  end

  def add_relationship?(relationship)
    relationship.strength >= 0.99 && !relationship.c1_is_sparser?
  end

  def preprocess_graph
    assert_only_root_has_no_incoming_edges
    @graph.merge_nodes
    @graph.break_cycles
  end

  def get_tables
    # Map of parent node to an array of children
    tables  = Hash.new do |h, k|
      h[k] = Array.new
    end

    # loop through vertices so that we include merged nodes etc
    @graph.graph.vertices.each do |v|
      parent = pick_parent(v)
      tables[parent] << v
    end

    # Any columns that were not represented (e.g. have no functional
    # relationships) should be added to the root
    tables[ROOT_NAME] +=
      @all_columns.to_a - (@graph.graph.vertices.to_a + @graph.merged_columns)

    tables
  end

  def pick_parent(column)
    return nil if column == ROOT_NAME
    @graph.get_longest_path_predecessor(column)
  end

  # Adds a vertex that points to all of the other columns in the graph in order
  # to ensure that there's a root
  def create_root_node
    @all_columns.each do |vertex|
      pair = ColumnPair.new
      pair.c1 = ROOT_NAME
      pair.c2 = vertex
      rel = Relationship.new(pair.c1, pair.c2, pair)
      @graph.add_relationship(rel)
    end
  end

  # There's something wrong if nodes other than the ROOT are without incoming
  # edges. The graph is malformed
  def assert_only_root_has_no_incoming_edges
    n_incoming = Hash.new
    @graph.graph.each_vertex { |v| n_incoming[v]  = 0 }
    @graph.graph.each_edge { |c1, c2| n_incoming[c2] += 1 }
    n_incoming.each do |k, v|
      raise AssertionError  if v == 0 && k != ROOT_NAME
    end
  end
end
