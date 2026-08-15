## ===========================================================================
## 16-fx-governance.R  --  the seam to the governance file (INTEGRATION §5.1).
##
## A detector's prediction feeds the DGF as a fixed set of per-variable fields.
## depth_labeled is the load-bearing one: a detector that resolves only to
## `number` writes depth_labeled = 1 and leaves the deeper fields empty. EMPTY
## IS A VALID ANSWER, not a failure -- the reviewer's job is to deepen it, not
## to correct it. The actual DGF is written by the governance-file package; this
## function only produces the contracted field set so that handoff is stable.
## ===========================================================================

#' Format a type prediction as governance-file (DGF) fields
#'
#' Produces the eight per-variable fields the DGF expects. Supply as much of the
#' path as the detector could resolve; deeper levels left `NA` are a legitimate
#' shallow (graceful) prediction, reflected in `depth_labeled`.
#'
#' @param data_type,semantic_family,semantic_type The resolved path prefix; any
#'   suffix may be `NA`.
#' @param semantic_type_id If given (and the path is not), the path is resolved
#'   from the ontology.
#' @param confidence Detector confidence in `[0,1]`, or `NA`.
#' @param detector_id Identifier of the detector that produced the guess, so a
#'   bad detector can be traced through the variables it touched.
#' @param ontology_version The ontology version the guess was made against;
#'   stored so a version bump can invalidate the guess (§5.2).
#' @param ont Ontology table for id resolution (defaults to [fx_ontology()]).
#'
#' @return A one-row data frame with `data_type`, `semantic_family`,
#'   `semantic_type`, `semantic_type_id`, `depth_labeled`, `confidence`,
#'   `ontology_version`, `detector_id`.
#' @export
fx_dgf_fields <- function(data_type = NA, semantic_family = NA, semantic_type = NA,
                          semantic_type_id = NA, confidence = NA_real_,
                          detector_id = NA, ontology_version = "v6", ont = NULL){

  ## resolve the path from a bare id when only the id is supplied
  if(!is.na(semantic_type_id) && is.na(data_type)){
    if(is.null(ont)) ont <- fx_ontology()
    r <- ont[ont$semantic_type_id == semantic_type_id, , drop = FALSE]
    if(nrow(r)){
      data_type       <- r$data_type[1]
      semantic_family <- r$semantic_family[1]
      semantic_type   <- r$semantic_type[1]
    }
  }

  lv <- c(data_type, semantic_family, semantic_type)
  ok <- !is.na(lv); ok[ok] <- nzchar(as.character(lv[ok]))
  ## depth must be a prefix: a gap (family missing but type present) is not a
  ## valid partial path, so count only the leading run of present levels.
  depth <- if(!ok[1]) 0L else { r <- rle(ok)$lengths; r[1] }

  data.frame(
    data_type        = as.character(data_type),
    semantic_family  = as.character(semantic_family),
    semantic_type    = as.character(semantic_type),
    semantic_type_id = as.character(semantic_type_id),
    depth_labeled    = as.integer(depth),
    confidence       = as.numeric(confidence),
    ontology_version = as.character(ontology_version),
    detector_id      = as.character(detector_id),
    stringsAsFactors = FALSE)
}
