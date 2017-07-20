require "byebug"
require "yaml"
require "optparse"
require "csv"

require "column_pair"
require "relationship"

options = {
  p1_output_directory: "p1_output",
  csv_output_path: "p1_output.csv"
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/p1_output_to_csv.rb [options]"

  opts.on(
    "--csv_output_path path",
    "The path where the final CSV should be written"
  ) do |path|
    options[:csv_output_path] = path
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

File.open(options[:csv_output_path], "w") do |f|
  c = CSV.new(f)
  c << Relationship.csv_header
  Relationship.from_directory(options[:p1_output_directory]).each do |rel|
    c << rel.to_csv
  end
end
