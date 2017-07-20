class MatchExplorer
  attr_reader :matches, :attribute_tree, :type_catalog, :rel_map

  # The minimum number of records in the JOIN result that must exist for
  # the pair to be included in our analysis
  SMALL_JOIN_THRESHOLD = 138

  # If the incompletion ratio of the smaller ratio is below this level,
  # a fatal_incomplete annotation will be added
  FATAL_INCOMPLETE_THRESHOLD = 0.5

  # Matches is an array of matches
  def initialize(matches, attribute_tree, type_catalog, output_stream = $stdout)
    @matches = matches
    @attribute_tree = attribute_tree
    @type_catalog = type_catalog
    @output_stream = output_stream

    @matches.each do |match|
      match.attribute_tree = @attribute_tree
      match.type_catalog = @type_catalog
    end
  end

  def self.from_directory(dir, *args)
    matches = Dir[File.join(dir, "*")].map do |fname|
      Match.deserialize(File.read(fname))
    end
    self.new(matches, *args)
  end

  # Prompt the user for the initialization parameters and then return
  # an initialized explorer
  def self.interactive_initialize
    if ARGV[0]
      attr_path = ARGV[0]
    else
      $stdout.puts "Where does the attr tree live?"
      attr_path = $stdin.gets.chomp
    end
    at = AttributeTree.from_file(attr_path)


    if ARGV[1]
      prof_path = ARGV[1]
    else
      $stdout.puts "Where does the type profile live?"
      prof_path = $stdin.gets.chomp
    end
    tc = TypeCatalog.from_directory(prof_path)

    if ARGV[2]
      match_dir = ARGV[2]
    else
      $stdout.puts "Which directory should we explore?"
      match_dir = $stdin.gets.chomp
    end

    from_directory(match_dir, at, tc)
  end

  # Runs all preprocessing functionality to prepare matches for printing/
  # matchmaking
  def preprocess_matches
    @matches.each(&:remove_self_matches)
    annotate_matches
    @rel_map = remap_matches
  end

  def annotate_matches
    matches.each do |match|
      annotate_small_join(match)
      annotate_pk_klass_mismatch(match, :raw)
      annotate_pk_klass_mismatch(match, :clustered)
      annotate_attr_klass_mismatch(match, :clustered)
      annotate_attr_klass_mismatch(match, :raw)
      annotate_same_relation_match(match)
      annotate_partial_match(match)
      annotate_pk_only_match(match)
    end
  end

  # Move from the space of PKs into the space of relations
  #
  # This allows more graceful handling of merged PKs
  def remap_matches
    relation_map = Hash.new do |h1, k1|
      h1[k1] = Hash.new { |h2, k2| h2[k2] = Array.new }
    end

    # Creates a list of matches for each relation pair
    @matches.each do |match|
      rel1 = attribute_tree.pk_to_relation(match.e1)
      rel2 = attribute_tree.pk_to_relation(match.e2)
      relation_map[rel1][rel2] << match
    end

    # Some of those merged nodes were duplicates
    deduped_relation_map = Hash.new do |h1, k1|
      h1[k1] = Hash.new { |h2, k2| h2[k2] = Array.new }
    end

    relation_map.each do |rel1, inner_map|
      inner_map.each do |rel2, inner_matches|
        seen = Set.new
        out = Array.new
        inner_matches.sort_by! { |m| [m.e1, m.e2] }
        inner_matches.each_with_index do |match1, match1_idx|
          next if seen.include?(match1)         #skip things that we've merged

          # Regardless of whether it's allowed to have merged nodes, it
          # should be marked as seen and put into the output list
          out << match1
          seen << match1

          # Don't allow a match that is dead to have other things
          # merged into it
          next if match1.has_fatal_annotation?

          next_idx = match1_idx + 1
          (next_idx...inner_matches.length).each do |match2_idx|
            match2 = inner_matches[match2_idx]
            if match1.merge?(match2)
              seen << match2
              match1.annotate_match(:merged_dup,
                                    "Same as #{match2.e1} -> #{match2.e2}")
            end
          end
        end

        deduped_relation_map[rel1][rel2] = RelationPair.new(rel1, rel2, out)
      end
    end

    deduped_relation_map
  end

  def print
    puts "Matches with fatal annotations (#{Match::FATAL_ANNOTATIONS})"\
         " are not shown"
    preprocess_matches
    @rel_map.each do |rel1, inner_rel_map|
      # Sort the RelationMatches on the number of live matches
      inner_keys = inner_rel_map.keys.sort_by do |inner_key|
        inner_rel_map[inner_key].live_matches.length
      end

      # Hide the matches w/o any strong pairings
      inner_keys.select! { |k|  inner_rel_map[k].live_matches.length > 0 }

      # Then print in the sorted order
      inner_keys.each do |rel2|
        inner_rel_map[rel2].print
      end

      puts ("-" * 10).concat("\n\n")
    end
  end


  # Matches ia nested hash structure that goes [rel1][rel2] -> rel_pair
  #
  # Each rel pair has two pairs pointing to it [rel1][rel2] and [rel2][rel1]
  #
  # Will find the parent closest to left that has some match with a
  # parent in right
  def self.identify_lowest_match(matches, left, right)
    while left
      r_node = right.parent

      while r_node
        if matches.key?(left) && matches[left].key?(r_node)
          return matches[left][r_node]
        end
        r_node = r_node.parent
      end

      left = left.parent
    end
  end

  # Remove overlapping matches between relations when they are "shadowed" by
  # matches that are higher in the tree.
  def draw_circles
    preprocess_matches
    circles = Hash.new do |h1, k1|
      h1[k1] = Hash.new
    end

    attribute_tree.breadth_first_traversal do |outer_rel|
      inner_rel_map = @rel_map[outer_rel]

      attribute_tree.breadth_first_traversal do |inner_rel|
        next if inner_rel == outer_rel || !inner_rel_map.key?(inner_rel)

        current_match = inner_rel_map[inner_rel]
        next if current_match.live_matches.empty?

        wrapping_match = self.class.identify_lowest_match(
          circles,
          outer_rel,
          inner_rel
        )

        if wrapping_match
          # Assert that wrapping_match.r1 is a parent of current_match.r1 and
          # wrapping_match.r2 is a parent of current_match.r2
          unless current_match.r1.descendant_of?(wrapping_match.r1) || current_match.r1 == wrapping_match.r1
            raise "Descendant mismatch"
          end

          unless current_match.r2.descendant_of?(wrapping_match.r2) || current_match.r2 == wrapping_match.r2
            raise "Descendant mismatch"
          end
        end

        unless wrapping_match && wrapping_match.can_shadow?(current_match)
          circles[outer_rel][inner_rel] = current_match
        end
      end
    end

    temp_circles = Hash.new do |h1, k1|
      h1[k1] = Hash.new
    end

    circles.each do |rel1, inner_hash|
      inner_hash.each do |rel2, match|
        if !temp_circles.key?(rel2) || !temp_circles[rel2].key?(rel1)
          temp_circles[rel1][rel2] = match
        end
      end
    end

    circles = temp_circles

    circles.each do |rel1, inner_hash|
      inner_hash.each do |rel2, match|
        puts "MATCH: #{rel1.pks} -> #{rel2.pks}\t\tNLIVE: #{match.live_matches.count}"
        match.print
      end
    end

    circles.values.map(&:values).flatten
  end

  private
  # The matches list likely contains every match in both directions. Cut it
  # down to one
  #
  # THIS IS PROBABLY NOT A GOOD IDEA -- NOT RUNNIGN FOR NOW
  def remove_duplicate_matches(matches)
    matches_hash = Hash.new { |h, k| h[k] = Hash.new }
    matches.each do |match|
      unless matches_hash[match.e1].has_key?(match.e2) ||
          matches_hash[match.e2].has_key?(match.e1)
        matches_hash[match.e1][match.e2] = match
      end
    end

    matches_hash.values.map(&:values).flatten
  end

  def annotate_small_join(match)
    if match.n_matches < SMALL_JOIN_THRESHOLD
      match.annotate_match(:small_join,
                           "Set smaller than #{SMALL_JOIN_THRESHOLD}")
    end
  end

  def annotate_pk_klass_mismatch(match, klass_type)
    method = "#{klass_type}_klass".to_sym
    annotation = "pk_#{klass_type}_klass_mismatch".to_sym

    e1_ty = type_catalog.send(method, match.e1)
    e2_ty = type_catalog.send(method, match.e2)

    if e1_ty != e2_ty
      match.annotate_match(annotation, "e1: #{e1_ty}\te2: #{e2_ty}")
    end
  end

  def annotate_attr_klass_mismatch(match, klass_type)
    method = "#{klass_type}_klass".to_sym
    annotation = "attr_#{klass_type}_klass_mismatch".to_sym

    match.attribute_matrix.each do |attr1, matrix|
      matrix.each_key do |attr2|
        a1_ty = type_catalog.send(method, attr1)
        a2_ty = type_catalog.send(method, attr2)

        if a1_ty != a2_ty
          match.annotate_matrix(attr1, attr2, annotation,
                                "a1: #{a1_ty}\ta2: #{a2_ty}")
        end
      end
    end
  end

  # Annotates when both sides of the match are included within the same
  # relation -- this only occurs when there are merged PKs and the
  # relation is compared against itself.
  #
  # TODO: prevent this behavior before actually doing the joins, as it'll
  # save a lot of time and cut out some of the most expensive and least
  # useful joins
  def annotate_same_relation_match(match)
    rel1 = attribute_tree.pk_to_relation(match.e1)
    rel2 = attribute_tree.pk_to_relation(match.e2)
    if rel1 == rel2
      match.annotate_match(:same_relation,
                           "Both from #{rel1.name} - #{rel1.pks}")
    end
  end

  # Adds annotations related to a scarcity of attributes that matching
  # (matching implies that all alignment criteria pass for the two attributes)
  def annotate_partial_match(match)
    e1_rel, e2_rel = rels = [attribute_tree.pk_to_relation(match.e1),
                             attribute_tree.pk_to_relation(match.e2)]

    if e1_rel.nil? || e2_rel.nil?
      raise "Missing either #{match.e1} or #{match.e2}"
    end

    lengths = {
      e1_rel => e1_rel.closure.length + match.e1_attr_count_adjustment,
      e2_rel => e2_rel.closure.length + match.e2_attr_count_adjustment }

    small, big = rels.sort_by { |r| lengths[r] }

    # identify the attr of e1/e2 that's smaller
    small_e = (e1_rel == small) ? match.e1 : match.e2
    # want the number of rows in the table where some column is greater
    # than the threshold
    n_strong_attr_matches = 0
    match.with_e1_as(small_e) do |match|
      match.accepted_attribute_matrix.each do |e1_attr, e2_attrs|
        # create an array of all the strengths for e1_attr
        if e2_attrs.values.length > 0
          n_strong_attr_matches += 1
        end
      end
    end

    n_strong_attr_matches -= 1
    lengths[small] -= 1

    incomplete_msg = "Covers only #{n_strong_attr_matches} non-join-pk attrs" \
    "(#{lengths[small]} in #{small.name} and #{lengths[big]} in #{big.name})"

    if n_strong_attr_matches <= lengths[small] * FATAL_INCOMPLETE_THRESHOLD
      match.annotate_match(:fatal_incomplete, incomplete_msg)
    elsif n_strong_attr_matches < lengths[small]
      match.annotate_match(:incomplete, incomplete_msg)
    end

    if n_strong_attr_matches == 0                   #we subtracted 1 above
      match.annotate_match(:single_attr_match, "")
    end
  end

  # Annotates matches where only attributes from the PKs overlap. This may
  # be an indication that the PKs have exactly the same content and thus
  # only match because the JOIN equality condition requires it
  def annotate_pk_only_match(match)
    rel1 = attribute_tree.pk_to_relation(match.e1)
    rel2 = attribute_tree.pk_to_relation(match.e2)

    match.accepted_attribute_matrix.each do |attr1, inner_hash|
      if !rel1.pks.include?(attr1)
       return  # saw a breaking object in the outer set
      end

      if inner_hash.keys.length > 0 && !(inner_hash.keys - rel2.pks).empty?
        return  # saw a breaking object in the inner set
      end
    end

    match.annotate_match(:pk_only, "")
  end

  def puts(str)
    @output_stream.puts(str)
  end
end
