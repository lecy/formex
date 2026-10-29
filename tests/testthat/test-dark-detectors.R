# §6.1 / §6.2 regression guards: the implemented-but-dark leaves that the router
# never shortlisted now route, because each carries a SELECTIVE recipe and is
# forced into the always-on verifier set (R/02-01-guess-data-type.R). These run
# under the shipped default ("auto" = learned router, signature fallback) -- the
# same path the benchmark and real callers use. The always-on set is
# router-independent, so a leaf confirms either way; the issn/date_range tie-break
# is resolved in the recipe (as_range yields a checksum-valid ISSN), also
# router-independent.
rt <- function(x, ...) guess_data_type(x, router = "auto", ...)$route

test_that("color codes route to their semantic_type (hex/rgb/hsl/cmyk)", {
  expect_equal(rt(c("#1A2B3C", "#0a0", "#ffffff", "#123456"))$semantic_type, "hex")
  expect_equal(rt(c("0x04db6f", "0x0e000b", "0x1ed442", "0x357d7d"))$semantic_type, "hex")
  expect_equal(rt(c("rgb(0,45,225)", "rgb(103,15,204)", "rgb(110,37,21)"))$semantic_type, "rgb")
  expect_equal(rt(c("0,0,0", "1,2,3", "104,9,2", "117,72,158"))$semantic_type, "rgb")
  expect_equal(rt(c("hsl(10,98%,67%)", "hsl(120,5%,77%)", "hsl(127,13%,0%)"))$semantic_type, "hsl")
  expect_equal(rt(c("0.01,0.53,0.33,0.02", "0.08,0.09,0.02,0.88", "0.19,0.79,0.0,0.0"))$semantic_type, "cmyk")
})

test_that("network and contact leaves route (ip / mac / phone)", {
  expect_equal(rt(c("0.0.0.0", "10.60.251.31", "127.0.0.1", "13.148.157.40"))$semantic_type, "ip")
  expect_equal(rt(c("2001:0db8:85a3:0000:0000:8a2e:0370:7334", "::1",
                    "::ffff:112a:7283"))$semantic_type, "ip")
  expect_equal(rt(c("01:23:45:67:89:ab", "0b:fe:24:8e:8b:72", "12:a4:83:4e:c5:a4"))$semantic_type, "mac")
  expect_equal(rt(c("05-e1-e1-ff-ae-8c", "1E-42-64-5E-54-69"))$semantic_type, "mac")
  expect_equal(rt(c("033b.ee2f.e681", "04c5.721d.4981", "0c2a.2ce8.d357"))$semantic_type, "mac")
  expect_equal(rt(c("215-403-9639", "247-309-7381", "252-385-1867"))$semantic_type, "phone")
  expect_equal(rt(c("(239) 663-7202", "(276) 566-9775", "(309) 647-1820"))$semantic_type, "phone")
})

test_that("postal po_box routes across its written forms", {
  expect_equal(rt(c("PO BOX 1077", "PO BOX 1105", "PO BOX 1206"))$semantic_type, "po_box")
  expect_equal(rt(c("P.O. Box 1194", "P.O. Box 1216"))$semantic_type, "po_box")
  expect_equal(rt(c("POB 1036", "POB 1057", "POB 121"))$semantic_type, "po_box")
  expect_equal(rt(c("Box 1326", "Box 2353", "Box 2743"))$semantic_type, "po_box")
})

test_that("period/month routes and does not lose to calendar or date_range", {
  expect_equal(rt(c("199006", "199210", "199408", "199501"))$semantic_type, "month")
  expect_equal(rt(c("1990-08", "1991-04", "1991-05", "1993-04"))$semantic_type, "month")
  expect_equal(rt(c("Apr 1990", "Aug 2004", "Aug 2013", "Dec 2019"))$semantic_type, "month")
  # a full calendar date (carries a day) must still win
  expect_equal(rt(c("2019-03-01", "2020-01-15", "2021-07-04"))$semantic_type, "calendar")
})

test_that("ISSN routes, and the NNNN-NNNN shape collision resolves to issn not date_range", {
  r <- rt(c("0001-2092", "0002-0729", "0004-4687", "0022-3476"))
  expect_equal(r$semantic_type, "administrative")
  expect_equal(r$format_label, "issn")                       # checksum-valid -> issn, not date_range
  # the ISSN-prefixed form still lands on the administrative id leaf
  expect_equal(rt(c("ISSN 0202-8538", "ISSN 0289-1422", "ISSN 0495-5951"))$semantic_type,
               "administrative")
  # a genuine year range is NOT a valid ISSN and must stay date_range
  expect_equal(rt(c("2000-2005", "2001-2008", "1936-1940", "1980-1989"))$semantic_type, "date_range")
})

test_that("boolean is detected at the data_type level across binary vocabularies", {
  expect_equal(rt(c("0", "1", "0", "1", "1", "0"))$data_type, "boolean")
  expect_equal(rt(c("yes", "no", "yes", "no", "yes"))$data_type, "boolean")
  expect_equal(rt(c("true", "false", "T", "F", "true"))$data_type, "boolean")
  expect_equal(rt(c("active", "inactive", "active", "inactive"))$data_type, "boolean")
  expect_equal(rt(c("on", "off", "on", "off"))$data_type, "boolean")
  expect_equal(rt(c("present", "absent", "present", "absent"))$data_type, "boolean")
  expect_equal(rt(c("0", "1"))$semantic_family, "binary")
  # a three-state categorical is NOT boolean (a third token breaks the binary gate)
  expect_false(isTRUE(rt(c("active", "inactive", "pending", "active", "pending"))$data_type == "boolean"))
})

test_that("literal fires only on a recognizable typed MIXTURE, never on a clean type", {
  expect_equal(rt(c("$1,200", "40%", "02168", "www.usa.com", "(605) 348-9999", "2019-03-01"))$semantic_type,
               "literal")
  # a mono-typed column keeps its own leaf; literal stays a last resort
  expect_false(isTRUE(rt(c("2019-03-01", "2020-01-15", "2021-07-04", "2018-12-31"))$semantic_type == "literal"))
  expect_false(isTRUE(rt(c("#1A2B3C", "#0a0", "#ffffff", "#123456"))$semantic_type == "literal"))
})

test_that("the ontology stays integrity-clean after the recipe/flag changes", {
  expect_equal(fx_validate_ontology(), character(0))
})
