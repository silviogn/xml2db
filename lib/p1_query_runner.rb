require "yaml"

require "column_pair"

class P1QueryRunner
  def initialize(
    thread_number:,
    query_cache:,
    database:,
    table_name:,
    output_directory:
  )
    @thread_number = thread_number
    @query_cache = query_cache
    @database = database
    @output_directory = output_directory
    @table_name = table_name
  end

  def process_combination(combination)
    @combination = combination
    initialize_column_pair
    populate_column_pair
    write_column_pair
  end

  private

  def initialize_column_pair
    @column_pair = ColumnPair.new
    @column_pair.c1 = @combination.first
    @column_pair.c2 = @combination.last
  end

  def populate_column_pair
    @column_pair.card_c1 = calculate_column_cardinality(@column_pair.c1)
    @column_pair.card_c2 = calculate_column_cardinality(@column_pair.c2)
    @column_pair.card_c1_c2 = calculate_pair_cardinality
    @column_pair.mode_c1 = calculate_column_mode(@column_pair.c1)
    @column_pair.mode_c2 = calculate_column_mode(@column_pair.c2)
    @column_pair.null_count_c1 = count_column_nulls(@column_pair.c1)
    @column_pair.null_count_c2 = count_column_nulls(@column_pair.c2)
    @column_pair.penalty_c1_c2 = calculate_penalty(
      @column_pair.c1,
      @column_pair.c2,
      @column_pair.mode_c2
    )

    @column_pair.penalty_c2_c1 = calculate_penalty(
      @column_pair.c2,
      @column_pair.c1,
      @column_pair.mode_c1
    )
  end

  def calculate_column_cardinality(column)
    query = <<-SQL
      SELECT COUNT(*) as result FROM (
        SELECT DISTINCT #{column} FROM #{@table_name}
      ) as r;
    SQL

    execute_query(query)
  end

  def calculate_pair_cardinality
    query = <<-SQL
      SELECT COUNT(*) as result FROM (
        SELECT DISTINCT #{@combination.join(",")} FROM #{@table_name}
      ) as r;
    SQL

    execute_query(query)
  end

  def calculate_column_mode(column)
    query = <<-SQL
      SELECT r.#{column} as result FROM (
        SELECT #{column}, count(*) as count FROM #{@table_name} GROUP BY #{column}
      ) as r
      ORDER BY count DESC
      LIMIT 1;
    SQL

    execute_query(query)
  end

  def count_column_nulls(column)
    query = <<-SQL
      SELECT COUNT(*) as result FROM #{@table_name} WHERE #{column} IS NULL;
    SQL

    execute_query(query)
  end

  def calculate_penalty(column1, column2, mode2)
    where_clause = if mode2.nil?
                     " IS NULL"
                   else
                     "::varchar = \'#{mode2}\'"
                   end

    query = <<-SQL
      SELECT COUNT(*) as result FROM (
        SELECT DISTINCT #{@combination.join(",")} FROM #{@table_name}
      ) as r
      WHERE #{column2}#{where_clause}
    SQL

    execute_query(query)
  end

  def write_column_pair
    File.open(output_path, "w") do |f|
      f.write(YAML.dump(@column_pair))
    end
  end

  def execute_query(sql)
    if @query_cache.key?(sql)
      @query_cache[sql]
    else
      result = @database[sql]
      @query_cache[sql] = result.first[:result]
    end
  end

  def output_path
    output_path_for(output_filename)
  end

  def output_path_for(filename)
    File.join(@output_directory, filename)
  end

  def output_filename
    return @output_filename unless @output_filename.nil?

    counter = 0
    filename_proc = -> { "#{@thread_number}_#{counter}" }
    counter += 1 while File.exist?(output_path_for(filename_proc.call))

    @output_filename = filename_proc.call
  end
end
