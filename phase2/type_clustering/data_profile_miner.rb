# Mines features about the data within a specific column. Generates
# output intended to be used in order to cluster attributes with
# similar data profiles
class DataProfileMiner
  # Base functionality shared among all profilers
  class BaseProfiler
    def self.applicable?(obj)
      raise NotImplemented
    end

    def process(obj)
      # By default this is a no-op
    end

    def results
      raise NotImplemented
    end
  end

  # A profiler designed for attributes that are strings
  class StringProfiler < BaseProfiler
    def initialize
      @lengths = Hash.new(0)      # maps length -> # of times seen
      @n_numerical = 0            # count of numerical characters ever seen
      @n_whitespace = 0           # count of amount of whitespace seen
      @n_punctuation  = 0
    end

    def self.applicable?(obj)
      obj.is_a?(String)
    end

    def process(str)
      @lengths[str.length] += 1
      @n_numerical += str.count("0-9")
      @n_whitespace += str.count(" ")
      @n_punctuation += str.count("!.\"',?")
    end

    def results
      results = AttributeProfile.new

      results.length_min = @lengths.keys.min
      results.length_max = @lengths.keys.max
      results.length_mean = lengths_mean
      results.num_ratio = @n_numerical.to_f / lengths_sum
      results.punc_ratio = @n_punctuation.to_f / lengths_sum
      results.white_ratio = @n_whitespace.to_f / lengths_sum
      results.length_var = lengths_var

      results.klass = String
      results
    end

    private
    def lengths_mean
      lengths_sum.to_f / n_lengths
    end

    def lengths_sum
      sum = 0
      @lengths.each do |length, freq|
        sum += freq * length
      end
      sum
    end

    def n_lengths
      @lengths.values.inject(:+)
    end

    def lengths_var
      m = lengths_mean
      sum = 0
      @lengths.each do |length, freq|
        sum += freq * (length - m)**2
      end

      sum.to_f / (n_lengths - 1)
    end
  end

  # A profiler for numeric types. Right now it just records the class,
  # but may be extended to more complex operations in the future
  class NumericProfiler < BaseProfiler
    def initialize
      @klass = nil
    end

    def self.applicable?(obj)
      obj.is_a? Numeric
    end

    def process(obj)
      # Handle case where klass is known
      if @klass
        if !(obj.class <= @klass)
          raise "Multiple classes seen within a single column"
        else
          return
        end
      end

      # Infer klass from object -- use only one Integer type
      if obj.is_a?(Integer)
        @klass = Integer
      else
        @klass = obj.class
      end
    end

    def results
      results = AttributeProfile.new
      results.klass = @klass
      results
    end
  end

  # Profiles boolean objects -- really just records their class
  class BooleanProfiler < BaseProfiler
    PSUEDO_CLASS = "boolean"

    def self.applicable?(obj)
      obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
    end

    def results
      results = AttributeProfile.new
      results.klass = PSUEDO_CLASS
      results
    end
  end

  # Profiles boolean objects -- really just records their class
  class DateProfiler < BaseProfiler
    PSUEDO_CLASS = "date"

    def self.applicable?(obj)
      obj.is_a?(Date) || obj.is_a?(DateTime)
    end

    def results
      results = AttributeProfile.new
      results.klass = PSUEDO_CLASS
      results
    end
  end

  # Maps supported classes to their profiler
  SUPPORTED_PROFILERS = [StringProfiler, NumericProfiler, BooleanProfiler, DateProfiler]

  def initialize(attr)
    @attr = attr.to_sym              #the attr to profile
    @profiler = nil                  #the profiler in use
  end

  # Runs the query and pumps the results into the core logic of the profiler
  def process
    start = Time.now
    puts "Beginning #{@attr}"
    begin
      Sequel.postgres(CONFIG[:db_hash]) do |db|
        db.fetch(query).use_cursor.each do |row|
          process_element(row[@attr])
        end
      end

    rescue Sequel::DatabaseError
      $stderr.puts "DB ERROR IN #{@attr}"
    end

    write_results
    puts "Time elapsed: #{Time.now.to_i - start.to_i} seconds for #{@attr}"
  end

  # If a profiler has been instantiated, it checks that the data type
  # belongs and then passes it down to the lower layer
  #
  # If it's the first data element, an appropriate profiler is created
  def process_element(data)
    if data.nil?
      return

    elsif @profiler && @profiler.class.applicable?(data)
      @profiler.process(data)
      return

    elsif @profiler && !@profiler.class.applicable?(data)
      raise ArgumentError, "Inconsistent class provided to profiler"
    end

    # Initialize the profiler
    profiler_idx = SUPPORTED_PROFILERS.index { |p| p.applicable?(data) }
    if profiler_idx.nil?
      raise ArgumentError, "Unprofilable type: #{data.class}"

    else
      @profiler = SUPPORTED_PROFILERS[profiler_idx].new
      process_element(data)
    end
  end

  def results
    if @profiler
      r = @profiler.results
      r.name = @attr
    else
      r = AttributeProfile.new
      r.name = @attr
      r.string = NilClass
    end

    r
  end

  def write_results
    File.open("profiles/#{@attr}", "w") do |f|
      f.write(results.serialize)
    end
  end

  private
  # The base query to load data into the profiler
  def query
    <<-SQL
      SELECT #{@attr} FROM #{CONFIG[:tbl_name]};
    SQL
  end
end
