module Helpers
  # Traverses to the leaves of an arbitrarily deep matrix and returns true
  # if they are identical
  def self.deep_matrix_comparison(m1, m2)
    return false if m1.class != m2.class

    if m1.is_a?(Hash)
      return false unless (m1.keys - m2.keys).empty?
      return false unless (m2.keys - m1.keys).empty?
      m1.each do |key, value|
        return false unless deep_matrix_comparison(value, m2[key])
      end

    elsif m1 != m2
      return false
    end

    true
  end
end
