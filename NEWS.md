# sergeant 0.3.1.9000

* fixed `src_drill()` example
* JDBC driver still in github repo but no longer included in pkg builds. See 
  README.md or `drill_jdbc()` help for more information on using the JDBC 
  driver with sergeant.

# sergeant 0.3.0.9000

* New DBI interface (to the REST API)
* dplyr interface now uses the DBI interace to the REST API
* CRAN checks pass besides size (removing JDBC driver in next dev iteration)

# sergeant 0.2.1.9000

* implemented a large subset of Drill SQL Functions <https://drill.apache.org/docs/about-sql-function-examples/>

# sergeant 0.2.0.9000

* experimental alpha dplyr driver

# sergeant 0.1.2.9000

* can pass RJDBC connections made with `drill_jdbc()` to `drill_query()`
* finally enaled `nodes` parameter to be a multi-element character vector as it said
  in the function description

# sergeant 0.1.2.9000

* support embedded drill JDBC connection

# sergeant 0.1.1.9000

* tweaked `drill_query()` and `drill_version()`

# sergeant 0.1.0.9000

* Added JDBC connector and included JDBC driver in the package (for now)
* Changed idiom to piping in a connection object
* Added a `NEWS.md` file to track changes to the package.



