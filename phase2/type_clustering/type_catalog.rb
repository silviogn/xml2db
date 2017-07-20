# A type catalog stores information about fields seen within the data set and
# allows type queries on the fieldset
#
# For types that have profile data associated with them, the catalog
# will also carry out type clustering.
class TypeCatalog
  CLUSTERABLE_KLASSES = [String]

  # Reads a directory of profiles and initializes a catalog from its
  # contents
  def self.from_directory(dir_path)
    profiles = Dir[File.join(dir_path, "*")].map do |elt_path|
      AttributeProfile.deserialize(File.read(elt_path))
    end

    self.new(profiles)
  end

  # Builds a type catalog from a flat array of profiles
  def initialize(profiles)
    @profiles = profiles

    @attribute_map = Hash.new
    @profiles.each { |p| @attribute_map[p.name.to_sym] = p }
  end

  # Performs the clustering of each class
  def cluster
    CLUSTERABLE_KLASSES.each { |k| cluster_klass(k) }
    self
  end

  # Prints attributes by cluster
  def print
    clusters = @attribute_map.keys.group_by { |a| clustered_klass(a) }
    clusters.each do |cluster, attrs|
      puts "CLUSTER: #{cluster}"
      attrs.sort.each do |attr|
        puts attr
      end
      puts "\n"
    end
  end

  # Returns the raw class associated with an attribute -- no clusted info
  # is included
  def raw_klass(attr)
    attr = attr.to_sym
    if @attribute_map.key?(attr)
      @attribute_map[attr].klass
    else
      raise ArgumentError, "Untyped attribute #{attr}"
    end
  end

  # Returns a clustered klass associated with an attribute -- matches will
  # only occur between attr A and B if they share their raw_klass and are
  # placed within the same cluster for that klass
  def clustered_klass(attr)
    attr = attr.to_sym
    if @attribute_map.key?(attr)
      attr = @attribute_map[attr]
      attr.clustered_klass || attr.klass
    else
      byebug
      raise ArgumentError, "Untyped attribute #{attr}"
    end
  end

  # Gives access to the raw list of profiles
  def profiles
    @attribute_map.values
  end

  private
  # Performs clustering on all attributes of a specific klass and binds the
  # results into the components
  def cluster_klass(klass)
    relevant_profiles = @profiles.select { |p| p.klass == klass }
    return if relevant_profiles.empty?

    # Build a labeled vector set for the clusterer
    vectors = Hash.new
    relevant_profiles.each do |profile|
      vectors[profile.name] = profile.feature_vector
    end

    c = Clusterer.new(vectors, relevant_profiles.first.field_labels)
    c.analyze.each do |attribute, cluster|
      profile = @attribute_map[attribute.to_sym]
      profile.clustered_klass = "#{profile.klass}#{cluster}"
    end
  end
end
