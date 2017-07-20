require "set"
require "table_generator"

options = {
  p1_output_directory: "p1_output",
  tree_output_path: "p1_attribute_tree.txt"
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/p1_output_to_attribute_tree.rb [options]"

  opts.on(
    "--tree_output_path path",
    "The path where the final attribute tree should be written"
  ) do |path|
    options[:tree_output_path] = path
  end

  opts.on(
    "--p1_output_directory path",
    "The path to the directory where the phase 1 output has been written"
  ) do |path|
    options[:p1_output_directory] = path
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

def pretty_print(tables:, starting_points:, output_stream:)
  table_names = tables.keys
  table_names.unshift(*starting_points)
  seen = Set.new
  until table_names.empty?
    current_parent = table_names.shift
    next if seen.include?(current_parent) || !tables.key?(current_parent)
    seen << current_parent

    output_stream.puts("PARENT: #{current_parent}")
    attrs = tables[current_parent].sort
    attrs.each do |attr|
      output_stream.puts(attr)
    end
    output_stream.puts("\n")

    table_names.unshift(*attrs)
  end
end

File.open(options[:tree_output_path], "w") do |f|
  pretty_print(
    tables: TableGenerator.new(options[:p1_output_directory]).get_tables,
    starting_points: [TableGenerator::ROOT_NAME],
    output_stream: f
  )
end
