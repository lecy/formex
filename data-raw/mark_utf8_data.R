# Mark the non-ASCII strings in the shipped data objects as UTF-8.
#
# `data_type_tests` (currency test cases: EUR/GBP/JPY symbols) and `ontology`
# (euro-strip recipes, DMS coordinate examples) legitimately carry non-ASCII
# characters. R CMD check's "checking data for non-ASCII characters" is a
# WARNING while the bytes are UTF-8 but marked "unknown"; marking them UTF-8
# downgrades it to the benign "marked UTF-8 strings" NOTE. The bytes are
# unchanged, so detection and comparisons are unaffected. Pure-ASCII strings
# stay "unknown" (R only honours the mark on strings with high bytes).

mark_utf8 <- function(x) {
  if (is.character(x)) { Encoding(x) <- "UTF-8"; return(x) }
  if (is.list(x))      { x[] <- lapply(x, mark_utf8); return(x) }
  x
}

load("data/data_type_tests.rda")
data_type_tests <- mark_utf8(data_type_tests)
save(data_type_tests, file = "data/data_type_tests.rda",
     version = 2, compress = "xz")

load("data/ontology.rda")
ontology <- mark_utf8(ontology)
save(ontology, file = "data/ontology.rda",
     version = 2, compress = "xz")

tools::resaveRdaFiles(c("data/data_type_tests.rda", "data/ontology.rda"))
cat("re-encoded + resaved data/*.rda\n")
