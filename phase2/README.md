# Automatic Generation of Normalized Relational Schemas from Nested Key-Value Data

This archive contains an basic implementation of phases 2 and 3 of the
algorithm described in the paper "Automatic Generation of Normalized Relational
Schemas from Nested Key-Value Data" (available
[here](http://cs-www.cs.yale.edu/homes/dna/papers/schemagen-sigmod16.pdf)).


Phase 1 is provided as a separate archive, as it has been packaged into
a more convenient form than the code included here.

## Dependencies
The code has been most recently tested with MRI Ruby 2.3, but should be
compatible with any Ruby version above version 2.0. In addition to the
language itself, the algorithm requires the libraries specified in
`Gemfile` which can be installed by running `bundle install` inside of
the directory.

Outside of the Ruby dependencies, the algorithm also requires access to
a Postgres database containing the analysis dataset (see the
instructions for preparing the dataset below). Any relatively modern
Postgres database should be compatible with the code. The Postgres user
provided to the algorithm must at the least be able to query the
analysis table and create tables of its own.

## Preparing the dataset
Before applying the algorithm to the dataset, it must be flattened into
a single table as described in Section 3 and Appendix A (note though
that the code has no explicit support for arrays of nested objects).
Once flattened, the dataset should be loaded into a single table within
the Postgres database.

Many of the scripts require access to the dataset in the database. On startup
they will check for the following environment variables:

        DB_NAME
        TBL_NAME
        DB_USER
        DB_PASSWORD
        DB_HOST

If they are not found in the environment, the scripts will ask for them
interactively.

## Running phase 2 and phase 3
There are a few steps required to run these two stages in their entirety.

1. In the root directory, run the analysis code to identify matches between
   pairs of relations in the phase 1 attribute tree. Run `ruby main.rb` to
   launch the script. This will ask you for the path to the phase 1 attribute
   tree. It will populate the `output` directory  with the results of its
   analysis.

2. In the `type_clustering` directory, run `ruby data_profile_main.rb <PATH TO
   FIELDS FILE>`. The fields file should have a list of all of the fields
   contained in the analysis dataset, with one field on each line. This
   will populate the `type_clustering/profiles` directory with statistics about
   each column in the dataset that will be used to cluster matchable attributes.

3. In the `type_clustering` directory, run `ruby clusterer_main.rb`. This
   will populate the `type_clustering/clustered_profiles` directory with the
   actual clustering of attributes.

4. In the root directory, run `ruby relation_designer/main.rb <ATTRIBUTE TREE PATH> type_clustering/clustered_profiles output` (substituting the correct attribute tree path).
   This will first print a summary of all of the identified phase 2 relation
   matches and will then print the phase 3 final schema.

