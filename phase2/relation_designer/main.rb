# Applies the RelationDesigner to a set of inputs
require_relative '../dependencies'

if ARGV.length != 3
  puts "Usage: main.rb attribute_tree_path type_prof_path match_path"
  Kernel.exit(-1)
end

if ARGV[0]
  attr_path = ARGV[0]
else
  $stdout.puts "Where does the attr tree live?"
  attr_path = $stdin.gets.chomp
end
at = AttributeTree.from_file(attr_path)


if ARGV[1]
  prof_path = ARGV[1]
else
  $stdout.puts "Where does the type profile live?"
  prof_path = $stdin.gets.chomp
end
tc = TypeCatalog.from_directory(prof_path)

if ARGV[2]
  match_dir = ARGV[2]
else
  $stdout.puts "Which directory should we explore?"
  match_dir = $stdin.gets.chomp
end
me = MatchExplorer.from_directory(match_dir, at, tc)
pairs = me.draw_circles

puts "FINALOUTPUT"
pairs.each(&:print)

metadata = RelationDesigner::Metadata.new(pairs)

stages = [RelationDesigner::MatchStage, RelationDesigner::CardinalityStage]

final_tree = stages.inject(at) do |tree, stage|
  stage.new(tree, metadata).transformed_attribute_tree
end

finalizer = RelationDesigner::Finalizer.new(final_tree)
finalizer.print_schema
