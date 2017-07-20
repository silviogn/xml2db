# Provides a serialization/deserialization wrapper around a column profile
class AttributeProfile
  # Fields withing @profile that should not be considered part of the profile/
  # the feature vector
  NON_PROFILE_FIELDS = %w(name klass clustered_klass)

  def initialize(profile = {})
    @profile = profile

    # NaNs are 0's -- happens mostly for variances that have a single elment
    @profile.each do |key, value|
      if value.is_a?(Float) && value.nan?
        @profile[key] = 0.0
      end
    end
  end

  def serialize
    YAML.dump(@profile)
  end

  def self.deserialize(text)
    self.new(YAML.load(text))
  end

  # Delegate setters/getters to the profile hash
  def method_missing(m, *args)
    m = m.to_s
    setter = /(.*)=$/.match(m)
    if setter
      raise ArgumentError, "setters need 1 arg" if args.length != 1
      @profile[setter[1]] = args.first

    else
      raise ArgumentError, "getters can't have args" if args.length > 0
      @profile[m]
    end
  end

  # Returns a vector of the field values sorted by field name
  def feature_vector
    out = []
    field_names.each { |f| out << @profile[f] }
    out
  end

  # Returns a sorted list of field names
  def field_names
    (@profile.keys - NON_PROFILE_FIELDS).sort
  end
end
