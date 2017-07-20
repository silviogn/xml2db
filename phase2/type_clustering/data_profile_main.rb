require "../dependencies.rb"

fields = File.readlines(ARGV[0]).map(&:chomp)

seen = Array.new
Dir["profiles/*"].each do |profile|
  profile = File.read(profile)
  seen << AttributeProfile.deserialize(profile).name.to_s
end

puts "Overall: #{fields.length}"
fields -= seen
puts "Remaining: #{fields.length}"

worker = ThreadedWorker.new(fields) do |field, i|
  dpm = DataProfileMiner.new(field)
  dpm.process
end
worker.run
