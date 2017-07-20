# A component normalizer takes an array of component values (e.g. all of the
# x[0] values would be put into an array and passed to this class) and performs
# statistics upon them.
#
# The primary goal is to produce z-scores for each component value to facilitate
# vector standarization.
class ComponentNormalizer
  def initialize(sample)
    @sample = sample
  end

  def mean
    sum = @sample.inject(:+).to_f
    sum / @sample.length.to_f
  end

  def variance
    sum = 0
    m = mean
    @sample.each do |ent|
      sum += (ent - m)**2
    end

    sum.to_f / (@sample.length - 1)
  end

  def std_dev
    Math.sqrt(variance)
  end

  def zscore(val)
    unless @sample.include?(val)
      raise ArgumentError, "Cannot take z-score for element out of sample"
    end


    (val - mean).to_f / std_dev
  end
end
