# TODO

## Rudimentary profiling

There is no easy way to profile PL/pgSQL besides adding `raise info '%', now`
manually. Piggly's instrumentation support procs could easily be extended to
print timestamps on each event. It's not clear how to present this information
in the report without it becoming cluttered.

## Coverage pragmas

Some loops and branches cannot be fully covered in practice. It might be useful
to extend piggly to recognize pragmas like `-- piggly: no coverage`, so certain
nodes wouldn't be tagged. However, it may ambiguous which node was intended to
be annotated in a nest of nodes... and should the pragma apply to the node's
descendants?

## Small things
* Support for user-provided stylesheet
* Remove linebreaks from Compiler::Trace, so error messages line numbers match
  the report and the original uninstrumented source
* Print the percent change in coverage after "Reporting coverage for ..."
* Option to generate index for all previously exercised procs, when -n was used to
  update coverage for specific procs.

## Pipe dream: Semi-static SQL/code analysis
* Dump database schema to a local file for offline analysis of procs or queries
* PL/PgSQL-specific analysis
  * Local variable shadowing a column
* General SQL analysis
  * Non-existant columns in INSERT, UPDATE, DELETE statements (eg using an alias that you forgot to define)
  * Inserts from larger field to smaller field (eg VARCHAR(10) into VARCHAR(9), which causes an error)
  * Joins on fields that don't have a foreign key relationship
