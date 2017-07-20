require_relative "dependencies"

# Step 1: Get the initial phase 1 data
$stderr.puts "Where is the phase 1 output?"
phase1 = $stdin.gets.chomp
attribute_tree = AttributeTree.from_file(phase1)
candidates = attribute_tree.candidate_keys

# Step 2: generate all possible combinations
combinations = Array.new
(0...candidates.length).each do |i|
  next if candidates[i] == "ROOT"
  rel_i = attribute_tree.pk_to_relation(candidates[i])
  ((i+1)...candidates.length).each do |j|
    next if candidates[j] == "ROOT"
    rel_j = attribute_tree.pk_to_relation(candidates[j])
    next if rel_i == rel_j

    combinations << [candidates[i], candidates[j]].sort
  end
end

# Step 3: prune finished
seen = Array.new
filenames_seen = Set.new
Dir["output/*"].each do |output|
  filenames_seen << output
  match = Match.deserialize(File.read(output))
  seen << [match.e1, match.e2].sort
end

puts "Overall: #{combinations.size}"
combinations = combinations - seen
puts "Remaining: #{combinations.size}"

# Start by creating unique versions of each relation if they don't already
# exist
worker = ThreadedWorker.new(attribute_tree.relations) do |relation, _|
  Sequel.postgres(CONFIG[:db_hash]) do |db|
    puts "Creating unique table for #{relation.pks}"
    QueryRunner.create_unique_table_from_relation(relation, db)
  end
end
worker.run

worker = ThreadedWorker.new(combinations.shuffle) do |combination, i|
  r1, r2 = combination

  qr = QueryRunner.new(r1, r2, attribute_tree, i)
  qr.process_combination.each do |match|
    name = "#{match.e1}_#{match.e2}"
    File.open(File.join("output", name), "w") { |f| f.write(match.serialize) }
  end
end
worker.run
