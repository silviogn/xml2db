class Clusterer
  include Ai4r::Clusterers
  include Ai4r::Data

  CLUSTERING_CLASS = BisectingKMeans

  class ClusteringException < Exception; end

  def initialize(vectors, vector_labels)
    vectors = VectorNormalizer.new(vectors).normalized_vectors
    @data_set = DataSet.new(data_items: vectors.values,
                            data_labels: vector_labels)
    @clusterer = CLUSTERING_CLASS.new

    # So we can go back from vectors to labels after analysis
    @vector_inverted_index = Hash.new { |h, k| h[k] = Array.new }
    vectors.each { |name, vector| @vector_inverted_index[vector] << name }
  end

  def analyze
    current_clustering = nil                            # best one seen so far
    current_cost = nil                                  # cost so far
    found_elbow = false                                 # has cost increased?

    max_n_clusters.times do |i|
      i = i + 1
      c = @clusterer.build(@data_set, i)

      candidate_cost = with_cluster_sum_of_squares(c.clusters)

      # beginning or cost improved
      if current_clustering.nil?  || candidate_cost <= current_cost
        current_clustering = c.clusters
        current_cost = candidate_cost

      else                                            # cost worsened
        found_elbow = true
        $stderr.puts "Clustering into #{i} groups"
        break
      end
    end

    unless found_elbow                            #manual intervention needed?
      raise ClusteringException
    end

    # Coerce clusters into appropriate form
    results = Hash.new
    current_clustering.each_with_index do |cluster, cluster_index|
      cluster.data_items.each do |vector|
        attributes = @vector_inverted_index[vector]
        attributes.each { |a| results[a] = cluster_index }
      end
    end

    results
  end

  def max_n_clusters
    20
  end

  # Move the printing of clusters into another function so that it can
  # be hooked into the cluster_test function for more analysis of
  # cluster shapes
  #
  # Should return a hash mapping attribute name -> cluster index
  def print_potential_clusterings
    10.times do |i|
      i = i + 1
      c = @clusterer.build(@data_set, i)
      $stderr.puts "Starting #{i} clsuters"
      puts "#{i} clusters - sum: #{with_cluster_sum_of_squares(c.clusters)}"

      c.clusters.each_with_index do |cluster, index|
        puts "Group #{index+1}"
        names = Set.new
        cluster.data_items.each do |vector|
          values = @vector_inverted_index[vector]
          names += values
        end
        puts names.to_a.sort
        puts "\n\n"
      end

      puts  "\n\n"
    end
  end

  # Takes a DataSet containing multiple vectors and returns a data item
  # representing its centroid
  def centroid(data_set)
    data_set.get_mean_or_mode
  end

  # Returns the euclidian distance between v1 and v2
  def distance(v1, v2)
    sum = 0
    v1.each_with_index do |v1_val, idx|
      sum += (v1_val - v2[idx])**2
    end
    Math.sqrt(sum)
  end

  def with_cluster_sum_of_squares(clusters)
    sum = 0.0

    clusters.each do |cluster|
      current_centroid = centroid(cluster)
      cluster.data_items.each do |vector|
        sum += distance(vector, current_centroid)**2
      end
    end

    sum
  end
end
