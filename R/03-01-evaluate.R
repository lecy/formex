##############################
### Evaluation harness (predictions vs. labeled columns)
###############################
## Scores formex against an EXTERNAL labeled column corpus (e.g. the Sherlock /
## VizNet 78-type benchmark). The corpus uses its own type vocabulary, so a
## `crosswalk` maps each source label to a formex (type, subtype, class) triple
## -- or to NA when the source type has no formex home (out of scope). We then
## run detection per column and score the predicted class against the crosswalked
## gold class.
##
## Two modes:
##   * use_name = FALSE (default): value-only, via guess_data_type(). This is the
##     honest test for corpora like Sherlock whose LABELS were derived from the
##     header (feeding the header back in would be circular).
##   * use_name = TRUE: full guess_column(), for corpora (e.g. GitTables) that
##     carry a real header independent of the semantic annotation.
##
## The scoring core is source-agnostic: give it a list of value vectors, their
## labels, and a crosswalk. Adapters that read a specific corpus live in
## data-raw/eval/.


## collapse a label to a comparison key (case/space/punctuation-insensitive):
## "Birth date", "birthDate", "birth_date" all -> "birthdate"
#' @keywords internal
#' @noRd
.norm_label <- function(x) gsub("[^a-z0-9]+", "", tolower(trimws(as.character(x))))

## map one source label to formex coordinates via the crosswalk
#' @keywords internal
#' @noRd
.crosswalk_lookup <- function(label, crosswalk) {
  i <- match(.norm_label(label), .norm_label(crosswalk$source_label))
  if (is.na(i)) return(c(type = NA_character_, subtype = NA_character_,
                         class = NA_character_))
  c(type  = crosswalk$data_type[i],
    subtype = crosswalk$data_subtype[i],
    class = crosswalk$data_class[i])
}

#' Evaluate formex predictions against a labeled column corpus
#'
#' @param columns A list of character vectors, one per labeled column.
#' @param labels A character vector of source-vocabulary labels, `length ==
#'   length(columns)`.
#' @param crosswalk A data frame with columns `source_label`, `data_type`,
#'   `data_subtype`, `data_class` mapping each source label to a formex triple
#'   (`data_class = NA` marks an out-of-scope label).
#' @param headers Optional character vector of real column headers (only used
#'   when `use_name = TRUE`).
#' @param use_name If `TRUE`, predict with [guess_column()] (values + name);
#'   otherwise value-only via [guess_data_type()].
#' @param ... Passed to the underlying guesser (e.g. `threshold`, `n_sample`).
#'
#' @return A data frame with one row per column: `label`, `gold_type`,
#'   `gold_class`, `pred_detector`, `pred_type`, `pred_class`, `source`,
#'   `in_scope`, `class_correct`, `type_correct`.
#' @seealso [eval_summary()]
#' @export
evaluate_columns <- function(columns, labels, crosswalk, headers = NULL,
                             use_name = FALSE, ...) {
  stopifnot(length(columns) == length(labels))
  rows <- vector("list", length(columns))
  for (i in seq_along(columns)) {
    gold <- .crosswalk_lookup(labels[i], crosswalk)
    if (use_name) {
      hdr <- if (!is.null(headers)) headers[i] else labels[i]
      g <- guess_column(columns[[i]], name = hdr, ...)
      det <- g$guess; src <- g$source
      pt <- g$ontology[["data_type"]]; pc <- g$ontology[["data_class"]]
    } else {
      g <- guess_data_type(columns[[i]], ...)
      det <- g$guess; src <- if (is.na(g$guess)) "none" else "value"
      pt <- g$ontology[["data_type"]]; pc <- g$ontology[["data_class"]]
    }
    rows[[i]] <- data.frame(
      label = labels[i],
      gold_type = unname(gold["type"]), gold_class = unname(gold["class"]),
      pred_detector = if (is.na(det)) NA_character_ else det,
      pred_type = pt, pred_class = pc, source = src,
      in_scope = !is.na(gold["class"]),
      class_correct = !is.na(gold["class"]) & !is.na(pc) & pc == gold["class"],
      type_correct  = !is.na(gold["type"])  & !is.na(pt) & pt == gold["type"],
      stringsAsFactors = FALSE, row.names = NULL)
  }
  do.call(rbind, rows)
}

#' Summarize an evaluation into overall and per-class metrics
#'
#' @param results Output of [evaluate_columns()].
#' @return A list with `overall` (a one-row data frame: column counts, class and
#'   type accuracy over in-scope columns, and prediction coverage) and
#'   `by_class` (per gold class: `support`, `recall`, `precision`, `f1`).
#'   Precision is computed over ALL predictions of a class (in- and out-of-scope
#'   columns), so a detector firing on out-of-scope columns is penalized.
#' @seealso [evaluate_columns()]
#' @export
eval_summary <- function(results) {
  ins <- results[results$in_scope, , drop = FALSE]
  overall <- data.frame(
    n_columns  = nrow(results),
    n_in_scope = nrow(ins),
    class_accuracy = if (nrow(ins)) mean(ins$class_correct) else NA_real_,
    type_accuracy  = if (nrow(ins)) mean(ins$type_correct)  else NA_real_,
    coverage = if (nrow(ins)) mean(!is.na(ins$pred_class)) else NA_real_,
    stringsAsFactors = FALSE)

  classes <- sort(unique(ins$gold_class))
  by_class <- lapply(classes, function(cl) {
    support  <- sum(ins$gold_class == cl)
    tp       <- sum(ins$gold_class == cl & !is.na(ins$pred_class) &
                    ins$pred_class == cl)
    pred_pos <- sum(!is.na(results$pred_class) & results$pred_class == cl)
    recall    <- tp / support
    precision <- if (pred_pos > 0) tp / pred_pos else NA_real_
    f1 <- if (!is.na(precision) && (precision + recall) > 0)
      2 * precision * recall / (precision + recall) else NA_real_
    data.frame(gold_class = cl, support = support, recall = recall,
               precision = precision, f1 = f1, stringsAsFactors = FALSE)
  })
  list(overall = overall,
       by_class = do.call(rbind, by_class)[order(-vapply(by_class,
                    function(d) d$support, numeric(1))), , drop = FALSE])
}
