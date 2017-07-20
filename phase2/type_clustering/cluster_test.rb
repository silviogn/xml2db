CONFIG = {}
require "./dependencies.rb"

profile_paths = ARGV[0]
cluster_count = ARGV[1].to_i

profiles = Dir[File.join(profile_paths, "*")].map do |path|
  AttributeProfile.deserialize(File.read(path))
end

vectors = Hash.new
profiles.each do |profile|
  vectors[profile.name] = profile.feature_vector
end

Clusterer.new(vectors, profiles.first.field_labels).analyze
