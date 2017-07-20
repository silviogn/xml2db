# Takes in a group of labeled vectors as a hash (label -> vector) and
# returns a hash of standardized vectors
class VectorNormalizer
  def initialize(vectors)
    @vectors = vectors
    @length = @vectors.values.first.length

    @vectors.each_value do |v|
      if @length != v.length
        raise ArgumentError, "all vectors must be the same degree"
      end
    end
  end

  def normalized_vectors
    #  Create a component normalizer for each component in the set
    component_normalizers = @length.times.map do |i|
      component_sample = @vectors.values.map { |v| v[i] }
      ComponentNormalizer.new(component_sample)
    end

    out = Hash.new

    @vectors.each do |name, vector|
      scaled_vector = out[name] = []
      vector.each_with_index do |value, idx|
        scaled_vector[idx] = component_normalizers[idx].zscore(value)
      end
    end

    out
  end
end
