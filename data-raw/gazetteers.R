## data-raw/gazetteers.R
## -----------------------------------------------------------------------------
## Provenance + regeneration for the person-name gazetteers embedded in
## R/dt-name-data.R (.first_names, .last_names).
##
## LICENSING (settled): both lists derive only from public-domain US-government
## frequency data, so the vectors may be redistributed inside the package with
## no attribution or share-alike obligation.
##
##   .first_names  <- Social Security Administration national baby-name data,
##                    bundled CC0 in the `babynames` package. Ranked by total
##                    births across all years/sexes; top 1000 taken (min ~50k
##                    lifetime births), which stays name-dominant into the tail
##                    (Edmund, Henrietta, Rosemarie, Ivy, Abel...) so recall
##                    rises without importing rare word-collision names.
##   .last_names   <- US Census Bureau "Frequently Occurring Surnames" (2010),
##                    public domain. The complete file (all 162,253 surnames
##                    occurring >=100 times) is the canonical source; the top
##                    2000 by count are taken (covers ~49% of surname mass, and
##                    the tail stays surname-dominant with no word collisions).
##                    The Census host (www2.census.gov) WAF-blocks scripted GETs
##                    and the api.census.gov data endpoint requires an API key,
##                    so this script reads a LOCAL copy of the official CSV. Get
##                    it from the Census page below or a public-domain mirror:
##                      https://census.gov/topics/population/genealogy/data/2010_surnames.html
##                      mirror: raw.githubusercontent.com/ddoxey/lastname/HEAD/data/Names_2010Census.csv
##                    Place it at data-raw/Names_2010Census.csv, then run this.
##
## The earlier dev-only gazetteer (dev/gazetteers/gaz.rds) carried an ~86k
## surname list of UNCERTAIN license (community "smashew" source). That list is
## used ONLY for offline router feature-engineering and is NOT shipped in the
## package; nothing under R/ or inst/ depends on it. The shipped detectors and
## fx_stabilize() lookups read only the public-domain vectors below.
##
## Run this script and paste the emitted blocks into R/dt-name-data.R.
## `babynames` is a data-raw-only dependency (not in DESCRIPTION Imports); the
## package carries the baked vectors, so no network access is needed at build or
## run time.
## -----------------------------------------------------------------------------

## emit a width-80 R literal block ready to paste into R/dt-name-data.R
emit_block <- function(sym, v, per_line = 8L, path) {
  q  <- sprintf('"%s"', sort(unique(v)))
  gr <- split(q, (seq_along(q) - 1L) %/% per_line)
  body <- paste0("  ", vapply(gr, paste, "", collapse = ", "))
  writeLines(c(sprintf("%s <- sort(unique(.norm_name(c(", sym),
               paste0(body, c(rep(",", length(body) - 1L), "")), "))))"), path)
  cat("wrote", length(q), "->", path, "\n")
}

## --- .first_names : top 1000 SSA given names by lifetime births (CC0) --------
if (!requireNamespace("babynames", quietly = TRUE))
  stop("install.packages('babynames') to regenerate .first_names")
bn  <- babynames::babynames
agg <- aggregate(n ~ name, data = bn, FUN = sum)
agg <- agg[order(-agg$n), ]
agg <- agg[!duplicated(tolower(agg$name)), ]
emit_block(".first_names", agg$name[seq_len(1000L)],
           path = "data-raw/gaz_first_names.txt")

## --- .last_names : top 2000 Census 2010 surnames by count (public domain) ----
csv <- "data-raw/Names_2010Census.csv"
if (file.exists(csv)) {
  d <- utils::read.csv(csv, stringsAsFactors = FALSE)
  d <- d[d$name != "ALL OTHER NAMES", ]
  d <- d[order(d$rank), ]
  title <- vapply(d$name[seq_len(2000L)],
                  function(s) sub("^(.)(.*)$", "\\U\\1\\L\\2", s, perl = TRUE), "")
  emit_block(".last_names", title, path = "data-raw/gaz_last_names.txt")
} else {
  cat("SKIP .last_names: place the Census CSV at", csv, "(see header)\n")
}
