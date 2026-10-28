## ===========================================================================
## 22-fx-transform-path.R -- v7 (EXPERIMENTAL): transformability as a path search
##
## A value's "format" is (semantic_type, unit_type, format_style). Stabilizing a
## column to a desired form is then a graph search: is there a path from the
## INPUT format to the DESIRED format through a registry of edges?
##
##   read_<style>        written form      -> canonical value      (parse half)
##   write_<style>       canonical value   -> written form         (render half)
##   convert_<u1>_<u2>   canonical (unit1) -> canonical (unit2)     (unit change)
##
## A path exists only "if you can get there from here": a unit change needs a
## registered convert_* edge, so e.g. temperature C -> F is transformable once
## convert_C_F is defined, while fiscal-year -> calendar-year is NOT until a
## converter (which needs the fiscal-year-end convention) is registered.
##
## This module is additive and not yet wired into guess_data_type()/fx_stabilize()
## -- it is the substrate the v7 ontology (format_style + unit_type axes) will
## resolve against. See ONTOLOGY-V7-PLAN.md.
## ===========================================================================

#' A value's format descriptor (v7, experimental)
#'
#' The three coordinates a transform search ranges over: the `semantic_type`
#' (what the value is), the `format_style` (how it is written -- field order,
#' separators, suffixes), and the `unit_type` (the dimensional/categorical unit
#' that carries meaning, e.g. `"C"`/`"F"`, `"USD"`, `"fiscal"`).
#'
#' @param semantic_type The ontology semantic type (e.g. `"calendar"`).
#' @param format_style The written rendering, or `NA`.
#' @param unit_type The dimensional/categorical unit, or `NA`.
#' @return An object of class `fx_format`.
#' @seealso [fx_plan_transform()]
#' @export
fx_format <- function(semantic_type, format_style = NA_character_,
                      unit_type = NA_character_) {
  structure(list(semantic_type = as.character(semantic_type),
                 format_style  = if (length(format_style)) as.character(format_style) else NA_character_,
                 unit_type     = if (length(unit_type))    as.character(unit_type)    else NA_character_),
            class = "fx_format")
}

#' @export
print.fx_format <- function(x, ...) {
  cat(sprintf("<fx_format %s | style=%s | unit=%s>\n",
              x$semantic_type, x$format_style, x$unit_type))
  invisible(x)
}

## node keys in the transform graph: written and canonical states
.fx_wnode <- function(sem, style) paste0("w|", sem, "|", style)
.fx_cnode <- function(sem, unit)  paste0("c|", sem, "|", unit)
.fx_edge  <- function(name, kind, from, to, fn)
  list(name = name, kind = kind, from = from, to = to, fn = fn)

## Ontology-derived read_ edges: every row with a format_style and a recipe
## contributes a written->canonical parse, keyed on its semantic_type + style.
## This connects the planner to the real type system (the read/parse direction);
## write_ renderers and convert_ edges are still hand-authored in the seed below
## and grown per style/unit.
## A usable unit NODE is a single resolved token (USD, C, F, fiscal); a "menu"
## of candidate units ("unit-specific (kg;;m;;C;;L)", "geographic level") is
## metadata, not a node, so it collapses to NA -- otherwise it pollutes the key
## and a plain measurement could never be addressed as c|measurement|NA.
.fx_clean_unit <- function(u) {
  if (is.na(u) || !nzchar(trimws(u)) || grepl(";;| ", u)) NA_character_ else trimws(u)
}

.fx_ontology_transforms <- function(ont = fx_ontology()) {
  edges <- list()
  for (i in seq_len(nrow(ont))) {
    style <- ont$format_style[i]
    if (is.na(style) || !nzchar(style)) next
    local({
      sem  <- ont$semantic_type[i]
      un   <- .fx_clean_unit(ont$unit_type[i])
      trr  <- ont$raw_to_stable_transform[i]
      edges[[length(edges) + 1L]] <<- .fx_edge(
        paste0("read_", style), "read",
        .fx_wnode(sem, style), .fx_cnode(sem, un),
        function(x) fx_transform(as.character(x), trr))
      ## number types: the canonical IS the number, so it renders to a plain
      ## "numeric" form by identity. This gives measurements etc. a write edge,
      ## so stabilizing to numeric is reachable rather than "no path".
      if (identical(ont$data_type[i], "number"))
        edges[[length(edges) + 1L]] <<- .fx_edge(
          "write_numeric", "write",
          .fx_cnode(sem, un), .fx_wnode(sem, "numeric"),
          function(x){ v <- suppressWarnings(as.numeric(gsub("[^0-9.eE+-]", "", as.character(x))))
                       ifelse(is.na(v), NA_character_, as.character(v)) })
    })
  }
  edges
}

## The hand-authored seed: write_ renderers and convert_ edges (and the read_
## edges for styles the ontology does not yet name). Merged with the
## ontology-derived read_ edges by fx_transforms().
.fx_seed_transforms <- function() {
  edges <- list(); add <- function(...) edges[[length(edges) + 1L]] <<- .fx_edge(...)

  ## temperature -- a genuine unit change gated on a registered converter
  add("read_celsius",     "read",  .fx_wnode("temperature","celsius"),    .fx_cnode("temperature","C"),
      function(x) as.numeric(gsub("[^0-9.+-]", "", x)))
  add("write_celsius",    "write", .fx_cnode("temperature","C"),          .fx_wnode("temperature","celsius"),
      function(x) paste0(round(as.numeric(x), 1), " C"))
  add("read_fahrenheit",  "read",  .fx_wnode("temperature","fahrenheit"), .fx_cnode("temperature","F"),
      function(x) as.numeric(gsub("[^0-9.+-]", "", x)))
  add("write_fahrenheit", "write", .fx_cnode("temperature","F"),          .fx_wnode("temperature","fahrenheit"),
      function(x) paste0(round(as.numeric(x), 1), " F"))
  add("convert_C_F",      "convert", .fx_cnode("temperature","C"),        .fx_cnode("temperature","F"),
      function(x) as.numeric(x) * 9/5 + 32)
  add("convert_F_C",      "convert", .fx_cnode("temperature","F"),        .fx_cnode("temperature","C"),
      function(x) (as.numeric(x) - 32) * 5/9)

  ## calendar date -- reformat only (canonical is ISO; no unit axis)
  add("read_mdy_slash",   "read",  .fx_wnode("calendar","mdy_slash"), .fx_cnode("calendar", NA),
      function(x) .fx_parse_iso_date(x))
  add("read_ymd_dash",    "read",  .fx_wnode("calendar","ymd_dash"),  .fx_cnode("calendar", NA),
      function(x) .fx_parse_iso_date(x))
  add("write_ymd_dash",   "write", .fx_cnode("calendar", NA), .fx_wnode("calendar","ymd_dash"),
      function(x) as.character(x))
  add("write_mdy_slash",  "write", .fx_cnode("calendar", NA), .fx_wnode("calendar","mdy_slash"),
      function(x) format(as.Date(x), "%m/%d/%Y"))

  ## fiscal year -- convert_fiscal_calendar is deliberately NOT registered, so a
  ## fiscal->calendar request is reported unreachable rather than guessed.
  add("read_FYyyyy",      "read",  .fx_wnode("year","FYyyyy"), .fx_cnode("year","fiscal"),
      function(x) as.integer(sub("^(?:FY|fy)\\s*", "", trimws(x))))
  add("write_bare",       "write", .fx_cnode("year","calendar"), .fx_wnode("year","bare"),
      function(x) as.character(x))
  edges
}

.fx_transform_cache <- new.env(parent = emptyenv())

#' The transform registry (v7, experimental)
#'
#' The list of edges [fx_plan_transform()] searches. Each edge is a
#' `read_`/`write_`/`convert_` step with a `from` node, a `to` node, and the
#' function that performs it.
#'
#' @return A list of transform edges.
#' @seealso [fx_plan_transform()]
#' @export
fx_transforms <- function() {
  if (is.null(.fx_transform_cache$edges))
    .fx_transform_cache$edges <- c(.fx_ontology_transforms(), .fx_seed_transforms())
  .fx_transform_cache$edges
}

#' Plan a transform from one format to another (v7, experimental)
#'
#' Breadth-first search over the transform [fx_transforms()] registry for the
#' shortest composition of `read_`/`convert_`/`write_` steps that takes a value
#' from the input format to the desired one. Returns the path, or a result
#' marked not transformable when no such path exists ("if you can get there from
#' here").
#'
#' @param from,to [fx_format()] descriptors.
#' @param registry A transform-edge list; defaults to [fx_transforms()].
#' @return An `fx_plan`: a list with `transformable` (logical), `path` (the
#'   ordered edges), `from`, `to`, and `reason` (when not transformable).
#' @seealso [fx_transformable()], [fx_apply_plan()]
#' @examples
#' fx_plan_transform(fx_format("temperature", "celsius", "C"),
#'                   fx_format("temperature", "fahrenheit", "F"))
#' @export
fx_plan_transform <- function(from, to, registry = NULL) {
  stopifnot(inherits(from, "fx_format"), inherits(to, "fx_format"))
  edges <- if (is.null(registry)) fx_transforms() else registry
  ## a format with no style IS the canonical value (a c| node); a style names a
  ## written form (a w| node). This lets a plan start or end at the canonical.
  node_of <- function(f)
    if (is.na(f$format_style) || !nzchar(f$format_style))
      .fx_cnode(f$semantic_type, f$unit_type) else .fx_wnode(f$semantic_type, f$format_style)
  start <- node_of(from)
  goal  <- node_of(to)
  res <- function(ok, path, reason = NA_character_)
    structure(list(transformable = ok, path = path, from = from, to = to,
                   reason = reason), class = "fx_plan")
  if (identical(start, goal)) return(res(TRUE, list()))

  adj  <- split(edges, vapply(edges, `[[`, "", "from"))
  seen <- start
  queue <- list(list(node = start, path = list()))
  while (length(queue)) {
    cur <- queue[[1]]; queue <- queue[-1]
    for (e in (adj[[cur$node]] %||% list())) {
      if (e$to %in% seen) next
      np <- c(cur$path, list(e))
      if (identical(e$to, goal)) return(res(TRUE, np))
      seen  <- c(seen, e$to)
      queue <- c(queue, list(list(node = e$to, path = np)))
    }
  }
  res(FALSE, NULL, sprintf("no path from [%s] to [%s]", start, goal))
}

#' Is one format reachable from another? (v7, experimental)
#' @inheritParams fx_plan_transform
#' @return `TRUE` if a transform path exists, else `FALSE`.
#' @seealso [fx_plan_transform()]
#' @export
fx_transformable <- function(from, to, registry = NULL)
  fx_plan_transform(from, to, registry)$transformable

#' Apply a transform plan to values (v7, experimental)
#' @param x A vector of values in the plan's `from` format.
#' @param plan An `fx_plan` from [fx_plan_transform()].
#' @return The values in the plan's `to` format.
#' @seealso [fx_plan_transform()]
#' @export
fx_apply_plan <- function(x, plan) {
  stopifnot(inherits(plan, "fx_plan"))
  if (!plan$transformable) stop("not transformable: ", plan$reason)
  for (e in plan$path) x <- e$fn(x)
  x
}

#' @export
print.fx_plan <- function(x, ...) {
  if (!x$transformable) {
    cat(sprintf("<fx_plan: NOT transformable -- %s>\n", x$reason))
    return(invisible(x))
  }
  steps <- vapply(x$path, `[[`, "", "name")
  cat(sprintf("<fx_plan: %s>\n",
              if (length(steps)) paste(steps, collapse = " :: ") else "identity"))
  invisible(x)
}
