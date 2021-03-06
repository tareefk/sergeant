#' Connect to Drill (using \code{dplyr}).
#'
#' Use \code{src_drill()} to connect to a Drill cluster and `tbl()` to connect to a
#' fully-qualified "table reference". The vast majority of Drill SQL functions have
#' also been made available to the \code{dplyr} interface. If you have custom Drill
#' SQL functions that need to be implemented please file an issue on GitHub.
#'
#' @note This is a DBI wrapper around the Drill REST API.
#' @note TODO username/password support
#'
#' @param host Drill host (will pick up the value from \code{DRILL_HOST} env var)
#' @param port Drill port (will pick up the value from \code{DRILL_PORT} env var)
#' @param ssl use ssl?
#' @export
#' @examples \dontrun{
#' db <- src_drill("localhost", "8047")
#'
#' print(db)
#'
#' emp <- tbl(db, "cp.`employee.json`")
#'
#' count(emp, gender, marital_status)
#'
#' # Drill-specific SQL functions are also available
#' select(emp, full_name) %>%
#'   mutate(        loc = strpos(full_name, "a"),
#'          first_three = substr(full_name, 1L, 3L),
#'                  len = length(full_name),
#'                   rx = regexp_replace(full_name, "[aeiouAEIOU]", "*"),
#'                  rnd = rand(),
#'                  pos = position("en", full_name),
#'                  rpd = rpad(full_name, 20L),
#'                 rpdw = rpad_with(full_name, 20L, "*"))
#' }
#' @export
src_drill <- function(host=Sys.getenv("DRILL_HOST", "localhost"),
                      port=as.integer(Sys.getenv("DRILL_PORT", 8047L)),
                      ssl=FALSE) {

  dr <- Drill()
  con <- dbConnect(dr, host=host, port=port, ssl=ssl)
  src_sql("drill", con)

}

#' @rdname src_drill
#' @keywords internal
#' @export
src_tbls.src_drill <- function(x) {
  tmp <- dbGetQuery(x$con, "SHOW DATABASES")
  paste0(unlist(tmp$SCHEMA_NAME, use.names=FALSE), collapse=", ")
}

#' @rdname src_drill
#' @keywords internal
#' @export
src_desc.src_drill <- function(x) {

  tmp <- dbGetQuery(x$con, "SELECT * FROM sys.version")
  version <- tmp$version
  tmp <- dbGetQuery(x$con, "SELECT (direct_max / 1024 / 1024 /1024) AS direct_max FROM sys.memory")
  memory <- tmp$direct_max

  sprintf("Drill %s [%s:%d] [%dGB direct memory]", version, x$con@host, x$con@port, memory)

}

#' @rdname src_drill
#' @keywords internal
#' @export
sql_escape_ident.DrillConnection <- function(con, x) {
  sql_quote(x, ' ')
}

#' @rdname src_drill
#' @keywords internal
#' @export
copy_to.src_drill <- function(dest, df) {
  stop("Not implemented.", call.=FALSE)
}

#' @rdname src_drill
#' @param src A Drill "src" created with \code{src_drill()}
#' @param from A Drill view or table specification
#' @param ... Extra parameters
#' @export
tbl.src_drill <- function(src, from, ...) {
  tbl_sql("drill", src=src, from=from, ...)
}

#' @rdname src_drill
#' @keywords internal
#' @export
db_explain.DrillConnection <- function(con, sql, ...) {
  explain_sql <- dplyr::build_sql("EXPLAIN PLAN FOR ", sql)
  explanation <- dbGetQuery(con, explain_sql)
  return(paste(explanation[[1]], collapse = "\n"))
}

#' @rdname src_drill
#' @keywords internal
#' @export
db_query_fields.DrillConnection <- function(con, sql, ...) {

  fields <- dplyr::build_sql(
    "SELECT * FROM ", sql, " LIMIT 1",
    con = con
  )
  result <- dbSendQuery(con, fields)
  return(dbListFields(result))

}

#' @rdname src_drill
#' @keywords internal
#' @export
db_data_type.DrillConnection <- function(con, fields, ...) {
  print("\n\n\ndb_data_type\n\n\n")
  data_type <- function(x) {
    switch(class(x)[1],
           logical = "BOOLEAN",
           integer = "INTEGER",
           numeric = "DOUBLE",
           factor =  "CHARACTER",
           character = "CHARACTER",
           Date = "DATE",
           POSIXct = "TIMESTAMP",
           stop("Can't map type ", paste(class(x), collapse = "/"),
                " to a supported database type.")
    )
  }
  vapply(fields, data_type, character(1))
}

#' @rdname src_drill
#' @keywords internal
#' @export
sql_translate_env.DrillConnection <- function(con) {
  x <- con
  dplyr::sql_variant(
    scalar=dplyr::sql_translator(
      .parent = dplyr::base_scalar,
      `!=` = dplyr::sql_infix("<>"),
      as.numeric = function(x) build_sql("CAST(", x, " AS DOUBLE)"),
      as.character = function(x) build_sql("CAST(", x, " AS CHARACTER)"),
      as.date = function(x) build_sql("CAST(", x, " AS DATE)"),
      as.posixct = function(x) build_sql("CAST(", x, " AS TIMESTAMP)"),
      as.logical = function(x) build_sql("CAST(", x, " AS BOOLEAN)"),
      cbrt = sql_prefix("CBRT", 1),
      degrees = sql_prefix("DEGREES", 1),
      e = sql_prefix("E", 0),
      lshift = sql_prefix("LSHIFT", 2),
      mod = sql_prefix("MOD", 2),
      negative = sql_prefix("NEGATIVE", 1),
      pi = sql_prefix("PI", 0),
      pow = sql_prefix("POW", 2),
      radians = sql_prefix("RADIANS", 1),
      rand = sql_prefix("RAND", 0),
      rshift = sql_prefix("RSHIFT", 2),
      trunc = sql_prefix("TRUNC", 2),
      convert_to = sql_prefix("CONVERT_TO", 2),
      convert_from = sql_prefix("CONVERT_FROM", 2),
      string_binary = sql_prefix("STRING_BINARY", 1),
      binary_string = sql_prefix("BINARY_STRING", 1),
      to_char = sql_prefix("TO_CHAR", 2),
      to_date = sql_prefix("TO_DATE", 2),
      to_number = sql_prefix("TO_NUMBER", 2),
      char_to_timestamp = sql_prefix("TO_TIMESTAMP", 2),
      double_to_timestamp = sql_prefix("TO_TIMESTAMP", 1),
      char_length = sql_prefix("CHAR_LENGTH", 1),
      flatten = sql_prefix("FLATTEN", 1),
      kvgen = sql_prefix("KVGEN", 1),
      repeated_count = sql_prefix("REPEATED_COUNT", 1),
      repeated_contains = sql_prefix("REPEATED_CONTAINS", 1),
      ilike = sql_prefix("ILIKE", 2),
      init_cap = sql_prefix("INIT_CAP", 1),
      length = sql_prefix("LENGTH", 1),
      lower = sql_prefix("LOWER", 1),
      ltrim = sql_prefix("LTRIM", 2),
      nullif = sql_prefix("NULLIF", 2),
      position = function(x, y) build_sql("POSITION(", x, " IN ", y, ")"),
      regexp_replace = sql_prefix("REGEXP_REPLACE", 3),
      rtrim = sql_prefix("RTRIM", 2),
      rpad = sql_prefix("RPAD", 2),
      rpad_with = sql_prefix("RPAD", 3),
      lpad = sql_prefix("LPAD", 2),
      lpad_with = sql_prefix("LPAD", 3),
      strpos = sql_prefix("STRPOS", 2),
      substr = sql_prefix("SUBSTR", 3),
      trim = function(x, y, z) build_sql("TRIM(", x, " ", y, " FROM ", z, ")"),
      upper = sql_prefix("UPPER", 1)
    ),
    aggregate=dplyr::sql_translator(.parent = dplyr::base_agg,
                                    n = function() dplyr::sql("COUNT(*)"),
                                    cor = dplyr::sql_prefix("CORR"),
                                    cov = dplyr::sql_prefix("COVAR_SAMP"),
                                    sd =  dplyr::sql_prefix("STDDEV_SAMP"),
                                    var = dplyr::sql_prefix("VAR_SAMP"),
                                    n_distinct = function(x) {
                                      dplyr::build_sql(dplyr::sql("COUNT(DISTINCT "), x, dplyr::sql(")"))
                                    }
    )
  )
}
