class MatrixFormatter
  attr_reader :matrix, :n_matches, :match

  def initialize(match, stream = $stdout)
    @matrix = match.attribute_matrix
    @n_matches = match.n_matches
    @match = match
    @output_stream = stream
  end

  def print
    present_e1_attrs = matrix.keys.sort
    present_e1_attrs.each do |attr|
      output_stream.puts "Attr: #{attr}"

      # Attribute, value pairs -- sorted by value
      present_e2_attr_pairs = matrix[attr].to_a.sort_by do |elt|
        elt.last
      end

      present_e2_attr_pairs.each do |elt|
        name = elt.first
        count = elt.last
        percentage = count.to_f / n_matches
        percentage_pretty = (percentage * 1000).floor / 1000.0
        annotations = match.get_matrix_annotations(attr, name).keys.
          map(&:to_s).join(" ")
        output_stream.write(
          "   #{name.ljust(60)}#{count.to_s.ljust(20)}(#{percentage_pretty})")
        unless annotations.empty?
          output_stream.write("  #{annotations}")
        end
        output_stream.write("\n")
      end
    end
  end

  private
  def output_stream
    @output_stream
  end
end
