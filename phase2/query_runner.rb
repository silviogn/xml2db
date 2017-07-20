class QueryRunner
  attr_reader :match1, :match2

  def initialize(rel1, rel2, attribute_tree, thread_i)
    @rel1 = rel1
    @rel2 = rel2

    # These things should proabbly be named rel and the above inst variables
    # should be named rel1pk and rel2pk, but since it's confined to just this
    # section I'm leaving it
    rel1_object = attribute_tree.pk_to_relation(rel1)
    rel2_object = attribute_tree.pk_to_relation(rel2)
    @rel1_closure = rel1_object.closure
    @rel2_closure = rel2_object.closure
    @rel1_analysis_table = rel1_object.unique_table_name
    @rel2_analysis_table = rel2_object.unique_table_name

    @match1 = Match.new          #match where rel1 points into rel2
    @match1.e1 = @rel1
    @match1.e2 = @rel2
    @match2 = Match.new          #match where rel2 points into rel1
    @match2.e1 = @rel2
    @match2.e2 = @rel1
    @thread_i = thread_i
    @combination_i = 0
  end

  # Join the base relation on e1 = e2 and then produce histograms of
  # attribute matchings
  def process_combination
    @match1.start = Time.now.to_f
    puts "Beginning #{@rel1}, #{@rel2}"

    n_rows = 0
    Sequel.postgres(CONFIG[:db_hash]) do |db|
      db.run("SET enable_mergejoin TO OFF;")
      db.fetch(create_analysis_table_query).use_cursor.each do |row|
        n_rows += row[:t1count] * row[:t2count]
        update_attribute_matrix(row)
      end
    end

    @match1.n_matches = @match2.n_matches = n_rows

    @match1.end = Time.now.to_f
    @match1.duration = @match1.start - @match1.end

    printf("Finishing #{@rel1}, #{@rel2}: time elapsed: %d seconds\n", @match1.duration)
    return [@match1, @match2]
  end

  # Query which selects the joined records that should be present in the
  # final output
  def create_analysis_table_query
    # Create the names of the fields that should be selected
    # enter each name first as a [tbl, name] pair
    fields = []
    [@rel1_closure, @rel2_closure].each_with_index do |rel_closure, rel_idx|
      rel_idx += 1
      rel_closure.each do |attr|
        fields << "tbl#{rel_idx}.#{attr} as #{rename(rel_idx, attr)}"
      end
    end


    <<-SQL
      SELECT #{fields.join(',')}, tbl1.count as t1count, tbl2.count as t2count
      FROM #{@rel1_analysis_table} as tbl1
      INNER JOIN #{@rel2_analysis_table} as tbl2
        ON tbl1.#{@rel1}::varchar = tbl2.#{@rel2}::varchar
      WHERE tbl1.#{@rel1} IS NOT NULL and
            tbl2.#{@rel2} IS NOT NULL and
            tbl1.#{@rel1}::varchar != '';
    SQL
  end

  def rename(rel_idx, attr)
    "tbl#{rel_idx}_#{attr}"
  end

  # Returns a list of all pairs of attributes within closure(e1) and closure(e2)
  def attribute_pairs
    unless @attribute_pairs
      @attribute_pairs = Array.new

      @rel1_closure.each do |a1|
        @rel2_closure.each do |a2|
          @attribute_pairs << [Attribute.new(1, a1), Attribute.new(2,a2)]
        end
      end
    end

    @attribute_pairs
  end

  private
  # Creates a temporary table containing all records where the two fields
  # match (this just runs a join)
  def create_analysis_table
    xact.exec(<<-SQL
        CREATE TEMPORARY TABLE #{analysis_table_name} AS
          #{create_analysis_table_query}
        ANALYZE #{analysis_table_name};
      SQL
    )
  end

  # Returns the number of records in the joined result
  def count_matches
    query = <<-SQL
      SELECT COUNT(*) as count FROM #{analysis_table_name};
    SQL

    xact.exec(query) do |pg_results|
      return pg_results[0]["count"].to_i
    end
  end

  # Updates the matrix with a specific row
  def update_attribute_matrix(row)
    mag = row[:t1count] * row[:t2count]
    attribute_pairs.each do |pair|
      if row[pair[0].aliased_name.to_sym] == row[pair[1].aliased_name.to_sym]
        @match1.attribute_matrix[pair[0].real_name][pair[1].real_name] += mag
        @match2.attribute_matrix[pair[1].real_name][pair[0].real_name] += mag
      end
    end
  end

  def analysis_table_name
    "analysis_table_#{@thread_i}"
  end

  # Get the transaction that should be used for current queries
  def xact
    if @xact.nil?
      raise "@xact must be set before attempting to use the current xact"
    end

    @xact
  end

  def self.create_unique_table_from_relation(relation, conn)
    columns = (relation.closure - ["ROOT"]).join(", ")
    conn.run "DROP TABLE IF EXISTS #{relation.unique_table_name}"
    conn.run <<-SQL
      CREATE TABLE #{relation.unique_table_name} AS
        (SELECT count(*), #{columns} FROM #{CONFIG[:tbl_name]}
           GROUP BY #{columns});
    SQL
    conn.run "ANALYZE #{relation.unique_table_name};"
  end

  class Attribute
    attr_reader :real_name, :aliased_name
    def initialize(rel_index, real_name)
      @real_name = real_name
      @aliased_name = "tbl#{rel_index}_#{real_name}"
    end
  end
end
