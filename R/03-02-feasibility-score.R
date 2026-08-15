##############################
### Feasibility-aware assignment scoring
###############################
## formex's ontology is a ground-up DETECTION taxonomy: type > class > subclass,
## where each level is a Russian-doll specialization of its parent (subclass
## inherits the class, adds specificity; a unit/system specializes the subclass
## further). Because a guess can back off to a higher level and still be
## partially right, we do NOT score a prediction against the ideal cell -- we
## score it against the DEEPEST LEVEL THAT IS FEASIBLE FROM THE VALUES ALONE.
##
## feasibility_score() grades one prediction on two independent axes:
##   * a path score (0/1/2): did we reach the feasible terminal node?
##       0 = reached the feasible ceiling on the correct path
##       1 = on the correct path but short of the feasible ceiling
##       2 = wrong branch (mismatch at some level) or no hit
##   * unit_recovered (0/1/NA): did we recover the unit / system / projection?
##       -- orthogonal to masking accuracy; NA when the type carries no unit.
##
## feasible_depth encodes the ceiling: 0 = not reachable on the ideal path at
## all (e.g. a bare 4-digit year is indistinguishable from an integer), 1 = type,
## 2 = class, 3 = subclass. A NULL ideal (all-empty) means the external type has
## no formex home: the correct behavior is to ABSTAIN, so abstaining scores 0 and
## any confident guess scores 2.


#' Score one ontology assignment by feasibility
#'
#' @param pred Character length-3 `c(type, class, subclass)`; use `NA`/`""` for
#'   levels the detector did not reach.
#' @param ideal Character length-3 `c(type, class, subclass)` from the crosswalk;
#'   all-empty means a NULL target (no formex home).
#' @param feasible_depth Integer 0-3: deepest level reachable from values on the
#'   ideal path (0 none, 1 type, 2 class, 3 subclass).
#' @param pred_unit,ideal_unit Optional unit/system/projection strings for the
#'   unit-recovery flag.
#'
#' @return A list with `score` (0/1/2) and `unit_recovered` (0/1/`NA`).
#' @export
feasibility_score <- function(pred, ideal, feasible_depth,
                              pred_unit = NA, ideal_unit = NA) {
  pred  <- as.character(pred);  ideal <- as.character(ideal)
  stopifnot(length(pred) == 3L, length(ideal) == 3L)
  blank <- function(x) is.na(x) | !nzchar(x)

  if (all(blank(ideal))) {                       # NULL target -> abstain is right
    score <- if (all(blank(pred))) 0L else 2L
  } else {
    md <- 0L                                     # matched depth along ideal path
    for (k in 1:3) {
      if (blank(ideal[k])) break
      if (!blank(pred[k]) && pred[k] == ideal[k]) md <- k else break
    }
    score <- if (md == 0L) 2L
             else if (md >= feasible_depth) 0L
             else 1L
  }

  unit_recovered <- if (blank(ideal_unit)) NA_integer_
                    else as.integer(!blank(pred_unit) && pred_unit == ideal_unit)
  list(score = score, unit_recovered = unit_recovered)
}

#' Score a table of predictions against a feasibility crosswalk
#'
#' @param preds A data frame with `type`, `class`, `subclass` columns (predicted;
#'   `NA` for unreached levels), optionally `unit`, and a `key` column linking to
#'   the crosswalk (defaults to matching by row order).
#' @param crosswalk A data frame with `v4_type`, `v4_class`, `v4_subclass`,
#'   `feasible_depth`, optional `unit`, one row per prediction (same order).
#'
#' @return `preds` with `score` and `unit_recovered` columns added.
#' @seealso [feasibility_score()]
#' @export
score_feasibility_table <- function(preds, crosswalk) {
  stopifnot(nrow(preds) == nrow(crosswalk))
  pu <- if ("unit" %in% names(preds)) preds$unit else rep(NA_character_, nrow(preds))
  iu <- if ("unit" %in% names(crosswalk)) crosswalk$unit else rep(NA_character_, nrow(crosswalk))
  out <- lapply(seq_len(nrow(preds)), function(i) {
    feasibility_score(
      pred  = c(preds$type[i], preds$class[i], preds$subclass[i]),
      ideal = c(crosswalk$v4_type[i], crosswalk$v4_class[i], crosswalk$v4_subclass[i]),
      feasible_depth = crosswalk$feasible_depth[i],
      pred_unit = pu[i], ideal_unit = iu[i])
  })
  preds$score          <- vapply(out, function(x) x$score, integer(1))
  preds$unit_recovered <- vapply(out, function(x) x$unit_recovered, integer(1))
  preds
}
