This work is based on work by Michael DiScala and Daniel Abadi
# Automatic Generation of Normalized Relational Schemas from Nested Key-Value Data

The data for this project is hosted at:
http://s3.amazonaws.com/discala-abadi-2016/index.html

This archive contains an basic implementation of the algorithm described
in the paper "Automatic Generation of Normalized Relational Schemas
from Nested Key-Value Data" (available
[here](http://cs-www.cs.yale.edu/homes/dna/papers/schemagen-sigmod16.pdf)).

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

As part of its input, the algorithm further requires a text file that
contains the names of all of the fields in the dataset, with one field
per line. For example:

    year
    quarter
    month

## Running the system
The scripts for invoking the algorithm are all within the `bin`
directory. In order to run them, you must prefix your call to ruby with
`bundle exec` to load the dependencies from the `Gemfile` and pass the
`-Ilib` flag to add the `lib` directory onto its load path. For example:

    bundle exec ruby -Ilib bin/p1_query_runner.rb --help

All of the scripts inside of `bin` accept a single `--help` flag, which
will display their required parameters.

The first script to run is `bin/p1_query_runner` which will process the
input dataset and evaluate potential functional relationships (this
gathers the data needed by Phase 1 -- see Section 3.1 of the paper).
This script will serialize its output into a folder of flat files. For
large datasets, the query runner may require a significant amount of
time to complete. You can interrupt it at any point, however, and it
will resume where it left off on a subsequent invocation.

The output of the query runner can be passed to `bin/p1_output_to_csv.rb`
to produce a CSV of all column pairs and their relevant statistics.

The output of the query runnner can also be passed to
`bin/p1_output_to_attribute_tree.rb` which will analyze the results and
produce the Phase 1 attribute tree as a separate flat file.

## Phases 2 & 3
The original implementation used in the writing of the paper exist as a
collection of scripts that require some expertise to successfully run
end-to-end. Before releasing these phases, we will be packaging them in
more standard wrappers similar to the phase 1 code that is included
here.
