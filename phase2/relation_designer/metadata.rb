# A class responsible for managing and gathering the metadata required by
# the relation designer
module RelationDesigner
  class Metadata
    attr_reader :pairs

    def initialize(pairs)
      @pairs = pairs
    end

    # Query the cardinality of a specific relation
    def get_cardinality(relation)
      query = relation.cardinality_query

      cardinality = nil
      Sequel.postgres(CONFIG[:db_hash]) do |db|
        cardinality = db.fetch(query).first[:result]
      end

      cardinality
    end
  end
end
