# A script to read in type profiles, print the clustering, and save it
# if accepted
CONFIG = {}
require_relative "../dependencies.rb"

tc = TypeCatalog.from_directory("profiles").cluster
tc.print

tc.profiles.each do |profile|
  serialized = profile.serialize
  File.open(File.join("clustered_profiles", profile.name.to_s), "w") do |f|
    f.write(serialized)
  end
end
