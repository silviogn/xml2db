require "byebug"
require "concurrent"
require "fileutils"
require "optparse"
require "set"
require "sequel"
require "parallel"
require "p1_query_runner"

options = {
  column_file: "field_list",
  n_threads: 6,
  database_url: "",
  table_name: "main",
  output_directory: "p1_output"
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/p1_query_runner.rb [options]"

  opts.on(
    "--threads N",
    Integer,
    "The number of threads to use for processing"
  ) do |n|
    options[:n_threads] = n
  end

  opts.on(
    "--column_file path",
    "The path to the file containing the list of fields to analyze"
  ) do |path|
    options[:column_file] = path
  end

  opts.on(
    "--database_url url",
    "The database to connect to"
  ) do |database_url|
    options[:database_url] = database_url
  end

  opts.on(
    "--table_name name",
    "The table containing the input data"
  ) do |table_name|
    options[:table_name] = table_name
  end

  opts.on(
    "--output_directory name",
    "The path to the directory where result files should be written"
  ) do |output_directory|
    options[:output_directory] = File.expand_path(output_directory)
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!


# Step 1: Get a list of all column names to analyze
column_names = IO.readlines(options[:column_file]).map(&:chomp)

# Step 2: Find all possible combinations of the column names
combinations = []
(0...column_names.length).each do |i|
  ((i+1)...column_names.length).each do |j|
    combinations << [column_names[i], column_names[j]].sort
  end
end

# Step 3: Prune any combinations that already have data in the output directory
seen = Array.new
FileUtils.mkdir_p(options[:output_directory])
Dir[File.join(options[:output_directory], "*")].each do |path|
  File.open(path, "r") do |f|
    yaml = f.read
    obj = YAML.load(yaml)
    seen << [obj.c1, obj.c2].sort
  end
end

puts "Total number of pairs: #{combinations.size}"
combinations = combinations - seen
puts "Number of pairs remaining: #{combinations.size}"

# Step 4: Run the remaining combinations in the appropriate number of threads
query_cache = Concurrent::Hash.new

#database = Sequel.connect(options[:database_url], max_connections: options[:n_threads])
database = Sequel.connect('postgres://postgres:123456@127.0.0.1:5432/sd')

Parallel.each(combinations, in_threads: options[:n_threads]) do |combination|
  query_runner = P1QueryRunner.new(
    thread_number: Parallel.worker_number,
    query_cache: query_cache,
    database: database,
    table_name: options[:table_name],
    output_directory: options[:output_directory]
  )

  query_runner.process_combination(combination)
end
