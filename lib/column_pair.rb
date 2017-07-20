# A ColumnPair represents two columns, C1 and C2, and carries various data
# regarding their relationship. The ordering of the columns is arbitrary
class ColumnPair
  attr_accessor :c1,            # name of c1
                :c2,            # name of c2
                :card_c1,       # number of unique values of c1
                :card_c2,       # number of unique values of c2
                :card_c1_c2,    # the number of unique (c1, c2) pairs
                :mode_c1,       # most frequent value of c1
                :mode_c2,       # most frequent value of c2
                :null_count_c1, # number of records where c1 is null
                :null_count_c2, # number of records where c2 is null
                :penalty_c1_c2, # the number of unique (c1, c2) pairs where
                                # c2 is mode_c2
                :penalty_c2_c1  # the number of unique (c1, c2) pairs where
                                # c1 is mode_c1
end
