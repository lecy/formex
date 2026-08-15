# ontology_diff (INTEGRATION §8): every change classified by semantic_type_id,
# with the data-driven impact matrix. A synthetic old->new pair exercises all
# nine change kinds; then the depth rule and write-isolation on banked cases.

mkont <- function(rows){
  d <- do.call(rbind, lapply(rows, function(r)
    data.frame(as.list(r), stringsAsFactors=FALSE)))
  for(cc in c("version_deprecated","superseded_by","short_desc"))
    if(is.null(d[[cc]])) d[[cc]] <- ""
  d
}
row <- function(id, fam, st, dt="number", dep="", sup="", sd="A", vid=NULL)
  c(semantic_type_id=id, variant_id=vid %||% paste0(id,"-f01"), data_type=dt,
    semantic_family=fam, semantic_type=st, version_deprecated=dep,
    superseded_by=sup, short_desc=sd)

old <- mkont(list(
  row("n0003","name","person","text"),
  row("n0004","mutually_exclusive","geographic","categorical"),
  row("n0005","portion","percent"),
  row("n0006","postal","full","text"),
  row("n0007","date","calendar","temporal"),
  row("n0008","currency","usd"),
  row("n0009","currency","euro", sd="A"),
  row("n0002","quantity","count")))

new <- mkont(list(
  row("n0003","name","person_full","text"),                         # renamed
  row("n0004","scale","geographic","categorical"),                  # moved (family)
  row("n0005","portion","percent", dep="v7", sup="n0002"),          # merged
  row("n0006","postal","full","text", dep="v7", sup="n0010 ;; n0011"), # split
  row("n0007","date","calendar","temporal", dep="v7"),              # deprecated
  row("n0008","currency","usd"),
  row("n0008","currency","usd", vid="n0008-f02"),                   # variant_add
  row("n0009","currency","euro", sd="B"),                           # attr_edit
  row("n0002","quantity","count"),
  row("n0010","postal","street","text"),                            # added (split tgt)
  row("n0011","postal","po_box","text")))                           # added (split tgt)

test_that("every change kind is classified on semantic_type_id", {
  d <- fx_ontology_diff(old, new)
  kind <- setNames(d$change_kind, d$semantic_type_id)
  expect_equal(kind[["n0003"]], "renamed")
  expect_equal(kind[["n0004"]], "moved")
  expect_equal(kind[["n0005"]], "merged")
  expect_equal(kind[["n0006"]], "split")
  expect_equal(kind[["n0007"]], "deprecated")
  expect_equal(kind[["n0008"]], "variant_add")
  expect_equal(kind[["n0009"]], "attr_edit")
  expect_true(all(c("n0010","n0011") %in% d$semantic_type_id[d$change_kind=="added"]))
  expect_false("n0002" %in% d$semantic_type_id)   # unchanged survivor not emitted
})

test_that("impact columns come from the data table, not ad hoc", {
  d <- fx_ontology_diff(old, new)
  imp <- fx_ontology_impact_table()
  m <- merge(d[, c("change_kind","case_impact","scoring_impact")], imp,
             by="change_kind", suffixes=c("",".ref"))
  expect_equal(m$case_impact, m$case_impact.ref)
  expect_equal(m$scoring_impact, m$scoring_impact.ref)
  # the two directions genuinely diverge
  expect_equal(imp$case_impact[imp$change_kind=="moved"], "none")
  expect_equal(imp$scoring_impact[imp$change_kind=="moved"], "all_pairs")
  expect_equal(imp$case_impact[imp$change_kind=="merged"], "mechanical")
})

test_that("impacted_cases applies the depth rule and write-isolation", {
  skip_if_not_installed("jsonlite")
  d <- fx_ontology_diff(old, new)
  dir <- tempfile(); dir.create(dir)
  wr <- function(id, st_id, depth) jsonlite::write_json(list(
      case_id=id, source=list(corpus="x"),
      label=list(semantic_type_id=st_id, depth_labeled=depth, ontology_version="v6",
                 needs_relabel=FALSE),
      difficulty=list(rating="hard"), profile=list(n=10), values=list(data=list())),
    file.path(dir, paste0(id,".json")), auto_unbox=TRUE)
  wr("c_merge", "n0005", 3)   # merged, depth 3 -> mechanical
  wr("c_split_deep", "n0006", 3)  # split, depth 3 -> review
  wr("c_split_shallow", "n0006", 1)  # split at depth 1 -> untouched (depth rule)

  res <- fx_impacted_cases(d, dir, write=TRUE)
  act <- setNames(res$action, res$case_id)
  expect_equal(act[["c_merge"]], "relabel_mechanical")
  expect_equal(act[["c_split_deep"]], "requeue_for_review")
  expect_false("c_split_shallow" %in% res$case_id)      # depth rule spared it

  # write-isolation: only label.needs_relabel / label.relabel_trigger were set
  o <- jsonlite::fromJSON(file.path(dir,"c_merge.json"), simplifyVector=FALSE)
  expect_true(isTRUE(o$label$needs_relabel))
  expect_true(nzchar(o$label$relabel_trigger))
  expect_equal(o$profile$n, 10)                          # other blocks untouched
})
