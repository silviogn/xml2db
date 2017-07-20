require "bundler/setup"
Bundler.require

require "thread"
require "yaml"
require "csv"
require "set"
require "pp"
require "fileutils"
require "rgl/topsort"
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'rgl/connected_components'

require_relative "helpers"
require_relative "attribute_tree"
require_relative "relation"
require_relative "threaded_worker"
require_relative "match"
require_relative "query_runner"
require_relative "matrix_formatter"
require_relative "match_explorer"
require_relative "relation_pair"
require_relative "relation_designer/stage_base"
require_relative "relation_designer/cardinality_stage"
require_relative "relation_designer/match_stage"
require_relative "relation_designer/finalizer"
require_relative "relation_designer/metadata"
require_relative "type_clustering/data_profile_miner"
require_relative "type_clustering/attribute_profile"
require_relative "type_clustering/component_normalizer"
require_relative "type_clustering/vector_normalizer"
require_relative "type_clustering/clusterer"
require_relative "type_clustering/type_catalog"

N_THREADS = 6

# If the configuration object has not been created already (e.g. in a test
# harness), then interactively populate whatever fields that the user might
# supply
unless defined? CONFIG
  CONFIG = Hash.new

  $stderr.puts "What database should I use?"
  CONFIG[:db_name] = ENV["DB_NAME"] || $stdin.gets.chomp

  $stderr.puts "\nWhat table should I use?"
  CONFIG[:tbl_name] = ENV["TBL_NAME"] || $stdin.gets.chomp

  $stderr.puts "\nWhat db user should I use?"
  CONFIG[:db_user] = ENV["DB_USER"] || $stdin.gets.chomp

  $stderr.puts "\nWhat db password should I use?"
  CONFIG[:db_password] = ENV["DB_PASSWORD"] || $stdin.gets.chomp

  $stderr.puts "\nWhat db host should I use?"
  CONFIG[:db_host] = ENV["DB_HOST"] || $stdin.gets.chomp

  CONFIG[:db_hash] = {
    database: CONFIG[:db_name],
    user: CONFIG[:db_user],
    password: CONFIG[:db_password],
    host: CONFIG[:db_host]
  }
end

