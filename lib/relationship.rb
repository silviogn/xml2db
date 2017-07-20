require "column_pair"
require "table_generator"

# A relationship models a FD candidate from c1 -> c2 based on the data
# stored in a ColumnPair object. Unlike ColumnPair objects -- which do not
# depend at all on the order of c1 and c2 -- Relationship objects rely on this
# ordering to indicate the direction of the functional dependency they're
# modeling
class Relationship
  def initialize(col_1_name, col_2_name, column_pair)
    if column_pair.c1 == col_1_name && column_pair.c2 == col_2_name
      @first_attr = :c1
      @second_attr = :c2
    elsif column_pair.c1 == col_2_name && column_pair.c2 == col_1_name
      @first_attr = :c2
      @second_attr = :c1
    else
      raise "Relationship initialized with mismatched ColumnPair"
    end

    @column_pair = column_pair
  end

  # An array of strings suitable to serve as a CSV file header
  def self.csv_header
    [
     "c1",
     "c2",
     "c1 cardinality",
     "c2 cardinality",
     "pair cardinality",
     "c1 mode",
     "c2 mode",
     "null count c1",
     "null count c2",
     "c1 is sparser",
     "strength"
    ]
  end

  # Opens all files in a directory, parses them as YAML column pairs, and
  # outputs the relationships
  def self.from_directory(dir_path)
    rels = []

    Dir[File.join(dir_path, "*")].each do |file|
      contents = IO.read(file)
      obj = YAML.load(contents)

      rels << Relationship.new(obj.c1, obj.c2, obj)
      rels << Relationship.new(obj.c2, obj.c1, obj)
    end

    rels
  end

  # An array of values matching the ColumPair.csv value
  def to_csv
    [
      c1,
      c2,
      c1_card,
      c2_card,
      pair_card,
      c1_mode,
      c2_mode,
      c1_null_count,
      c2_null_count,
      c1_is_sparser?,
      strength
    ]
  end

  def c1
    @column_pair.send(@first_attr)
  end

  def c2
    @column_pair.send(@second_attr)
  end

  def c1_card
    @column_pair.send("card_#{@first_attr}".to_sym)
  end

  def c2_card
    @column_pair.send("card_#{@second_attr}".to_sym)
  end

  def c1_mode
    @column_pair.send("mode_#{@first_attr}".to_sym)
  end

  def c2_mode
    @column_pair.send("mode_#{@second_attr}".to_sym)
  end

  def pair_card
    @column_pair.card_c1_c2
  end

  def c1_null_count
    @column_pair.send("null_count_#{@first_attr}")
  end

  def c2_null_count
    @column_pair.send("null_count_#{@second_attr}")
  end

  # @return [Boolean] is the number of rows c1 is defined on less than the
  # number of rows that c2 is defined on?
  def c1_is_sparser?
    c1_null_count > c2_null_count
  end

  # @return [Float] the strength of this relationship as defined in Formula
  # 3.1.2:
  #        # of distinct C1 vals - # of distinct pairs where c2 is modal
  #        -----------------------------------------------------------
  #        # of distinct pairs - # of distinct pairs where c2 is modal
  def strength
    # Relationships from the root to other nodes should always be retained
    # in the final graph, so have them return the strongest possible value
    return 1.0 if c1 == TableGenerator::ROOT_NAME

    penalty = @column_pair.send("penalty_#{@first_attr}_#{@second_attr}").to_f
    numerator = c1_card - penalty
    denominator = pair_card - penalty

    if denominator == 0
      0.0
    else
      numerator.to_f / denominator.to_f
    end
  end
end
