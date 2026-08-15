## ===========================================================================
## 17-fx-triage.R  --  field-quality triage, the gate before banking.
##
## A column is not automatically a good test case. Before we spend a label on
## it, decide what it is: corrupted (skip with a receipt), empty/degenerate
## (skip), a label-vs-value mismatch (bank but flag for relabel), or a clean /
## hard genuine example (bank, difficulty-rated). Corpus corruption should be
## excluded LOUDLY, never silently dropped.
## ===========================================================================

## difficulty heuristic shared with the bank builders
.fx_difficulty <- function(ft){
  g <- function(k){ v <- ft[[k]]; if(is.null(v) || is.na(v)) 0 else v }
  m <- character(0); hard <- mild <- 0L
  if(g("mask_top_share") < 0.5){ hard <- hard+1L; m <- c(m,"mixed_subformats") }
  else if(g("mask_top_share") < 0.9){ mild <- mild+1L; m <- c(m,"mixed_subformats") }
  if(g("pct_sentinel_na") > 0){ mild <- mild+1L; m <- c(m,"sentinel_missing") }
  if(g("pct_trail_ws") > 0 || g("pct_lead_ws") > 0){ mild <- mild+1L; m <- c(m,"whitespace_damage") }
  if(g("pct_all_upper") > 0.05 && g("pct_title_case") > 0.05){ mild <- mild+1L; m <- c(m,"mixed_case") }
  if(g("pct_nonascii") > 0.01){ mild <- mild+1L; m <- c(m,"encoding_damage") }
  list(rating = if(hard>=1L) "hard" else if(mild>=1L) "medium" else "easy",
       markers = unique(m))
}

#' Triage a column for banking as a test case
#'
#' Classifies a field into a quality verdict before it costs a label. Corrupted
#' and empty fields are excluded (with reasons); label-vs-value mismatches are
#' banked but flagged; clean fields are difficulty-rated.
#'
#' @param x A column (any vector).
#' @param expected_data_type Optional `data_type` the corpus label implies
#'   (e.g. `"number"`); enables the numeric-vs-text mismatch check.
#' @param features Optional precomputed [fx_extract_features()] row (avoids
#'   recomputation in a batch).
#'
#' @return A list: `verdict` (`"garbage"` | `"empty"` | `"mismatch"` |
#'   `"clean"` | `"hard"`), `keep` (bank it?), `reasons`, `difficulty`,
#'   `noise_markers`.
#' @seealso [fx_extract_features()]
#' @export
fx_triage_field <- function(x, expected_data_type = NA, features = NULL){
  ft <- if(is.null(features)) fx_extract_features(x) else features
  g  <- function(k){ v <- ft[[k]]; if(is.null(v) || is.na(v)) NA_real_ else v }
  out <- function(verdict, keep, reasons, rating = NA_character_, markers = character(0))
    list(verdict = verdict, keep = keep, reasons = reasons,
         difficulty = rating, noise_markers = markers)

  ## --- empty / degenerate -------------------------------------------------
  nu <- g("n_usable")
  if(is.na(nu) || nu < 8)                      return(out("empty", FALSE, "n_usable < 8"))
  if(isTRUE(g("is_constant") == 1))            return(out("empty", FALSE, "constant column"))
  if(isTRUE(g("pct_sentinel_na") > 0.9))       return(out("empty", FALSE, "all-sentinel"))

  ## --- garbage / corruption ----------------------------------------------
  r <- character(0)
  if(isTRUE(g("pct_nonascii") > 0.15))
    r <- c(r, sprintf("non-ascii %.0f%% (mojibake)", 100*g("pct_nonascii")))
  if(isTRUE(g("pct_chr_punct") > 0.5 && g("pct_chr_alpha") < 0.2 && g("pct_chr_digit") < 0.2))
    r <- c(r, "punctuation-dominant")
  if(isTRUE(g("mask_top_share") > 0.9 && (g("pct_chr_alpha") + g("pct_chr_digit")) < 0.15))
    r <- c(r, "single-punctuation mask")
  if(length(r))                                return(out("garbage", FALSE, r))

  ## --- label-vs-value mismatch -------------------------------------------
  diff <- .fx_difficulty(ft)
  if(!is.na(expected_data_type)){
    obs_num <- isTRUE(g("coerce_rate_strip") > 0.7)
    exp_num <- identical(expected_data_type, "number")
    if(exp_num != obs_num)
      return(out("mismatch", TRUE,
                 sprintf("values look %s but label implies %s",
                         if(obs_num) "numeric" else "non-numeric",
                         if(exp_num) "numeric" else "non-numeric"),
                 diff$rating, diff$markers))
  }

  ## --- clean / hard -------------------------------------------------------
  verdict <- if(diff$rating == "hard") "hard" else "clean"
  out(verdict, TRUE, "genuine example", diff$rating, diff$markers)
}
