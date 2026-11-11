# The zero-leak lexicon tie-break (stage 1a of .fx_route_verify()).
#
# Covers the case where the VERIFIER has clean partial-coverage evidence and the
# learned router disagrees: a surname column whose lexicon covers only ~43% of
# its values. The lexicon is right and the router is not, so the tie-break
# prefers the lexicon -- but only under gates narrow enough that it cannot
# disturb a selective leaf, a confident router, a short column, or a code
# lexicon reached through a shape mask.

## 200 MLB surnames, sampled from the 607 distinct values of
## datagoodr::dg_baseball$nameLast and stratified to preserve that column's
## real is_last_name() coverage (43% in / 57% out). Heavily Latin American and
## Japanese, which is exactly why the Anglo-weighted surname lexicon
## under-covers them. Also a useful development sample for any work on name
## detection: the misses are real surnames, not noise.
surnames_200 <- c(
  "Abad", "Abreu", "Ackley", "Adduci", "Ahmed", "Allen", "Alonso", "Altuve",
  "Alvarez", "Amarista", "Ambriz", "Anderson", "Barnes", "Barney", "Beato",
  "Beavan", "Bedrosian", "Belt", "Betances", "Bethancourt", "Bianchi",
  "Black", "Bogusevic", "Bour", "Bourjos", "Brothers", "Brown", "Bundy",
  "Butler", "Campana", "Campbell", "Carrera", "Cassevah", "Castillo",
  "Cedeno", "Cespedes", "Chafin", "Chambers", "Chapman", "Chisenhall",
  "Claudio", "Colabello", "Coleman", "Collins", "Colon", "Conger", "Cook",
  "Crockett", "Cruz", "Deduno", "Demel", "Descalso", "DeSclafani",
  "Dickerson", "Diekman", "Dozier", "Drabek", "Dyson", "Edgin", "Emaus",
  "Familia", "Farmer", "Federowicz", "Fernandez", "Figueroa", "Foltynewicz",
  "Franco", "Franklin", "Freeman", "Freiman", "Friedrich", "Fryer", "Geltz",
  "Germen", "Goins", "Goldschmidt", "Grandal", "Greene", "Grossman",
  "Guerra", "Hagadone", "Harper", "Harrell", "Harris", "Harrison", "Harvey",
  "Hatcher", "Heisey", "Hellickson", "Hembree", "Hendriks", "Herrera",
  "Heyward", "Hicks", "Hoes", "Holland", "Hoover", "Hughes", "Hutchison",
  "Jennings", "Kelly", "Kipnis", "Kirkman", "Kluber", "Komatsu", "Kratz",
  "La Stella", "Lambo", "Lawrie", "Lindblom", "Locke", "Lucroy", "Lueke",
  "Lutz", "Lynn", "Maldonado", "Maness", "Marte", "Martin", "Maurer",
  "McHugh", "Mendez", "Minor", "Monasterios", "Moore", "Morris", "Morrison",
  "Murphy", "Navarro", "Negron", "Neris", "Oberholtzer", "Olt", "Ortiz",
  "Owings", "Pacheco", "Panik", "Paredes", "Pastornicky", "Paterson",
  "Paxton", "Pillar", "Pirela", "Pollock", "Pompey", "Presley", "Profar",
  "Puig", "Quackenbush", "Raynor", "Rendon", "Rosario", "Rosenberg", "Ruf",
  "Rusin", "Rutledge", "Sale", "Sands", "Sardinas", "Satin", "Schoop",
  "Segura", "Semien", "Shaw", "Shuck", "Skaggs", "Smoak", "Smyly", "Soto",
  "Springer", "Stanton", "Stewart", "Strange-Gordon", "Strickland",
  "Stroman", "Suarez", "Sucre", "Tabata", "Tanaka", "Terdoslavich",
  "Texeira", "Thames", "Thielbar", "Thompson", "Tolleson", "Tomlin",
  "Torres", "Turner", "Valdespin", "Valencia", "Varvaro", "Venters",
  "Vizcaino", "Walker", "Wallace", "Webb", "Wheeler", "Workman", "Worth",
  "Young"
)

test_that("the 200-surname sample has the coverage this file assumes", {
  expect_length(surnames_200, 200L)
  expect_false(anyDuplicated(surnames_200) > 0)
  cov <- mean(vapply(surnames_200, function(x) isTRUE(is_last_name(x)), logical(1)))
  # ~43%: well under confirm_thr (0.80), well over tie_confirm_thr (0.25).
  expect_gt(cov, 0.35)
  expect_lt(cov, 0.55)
})

test_that("a partial-coverage surname lexicon beats the router's class prior", {
  r <- guess_data_type(surnames_200, seed = 1L, n_sample = 200)$route
  expect_equal(r$data_type, "text")
  expect_equal(r$semantic_family, "name")
  expect_equal(r$semantic_type, "person")
  expect_equal(r$router_method, "lexicon-tiebreak")
  # honest about its own strength: the leaf IS identified (depth 4), but the
  # confidence is the lexicon's actual confirm rate, not a promoted 1.0.
  expect_equal(r$depth, 4L)
  expect_lt(r$confidence, 0.60)
  expect_gt(r$confidence, 0.25)
})

test_that("disabling the tie-break restores the router's answer", {
  r <- guess_data_type(surnames_200, seed = 1L, n_sample = 200,
                          tie_confirm_thr = 1)$route
  # the documented escape hatch: tie_confirm_thr = 1 stands the stage down, and
  # the learned router then calls these surnames a geographic categorical.
  expect_equal(r$router_method, "learned")
  expect_equal(r$semantic_type, "geographic")
})

test_that("a confident router keeps the call (the tie_router_max ceiling)", {
  # repeating US city names route to categorical/geographic at ~0.99. A clean
  # place lexicon also confirms here, so without the ceiling the tie-break
  # would steal this column; the ceiling is what makes it stand down.
  cities <- rep(c("Chicago", "Boston", "Austin", "Denver", "Miami", "Seattle",
                  "Portland", "Atlanta", "Houston", "Phoenix"), each = 4)
  r <- guess_data_type(cities, seed = 1L)$route
  expect_equal(r$semantic_type, "geographic")
  expect_false(identical(r$router_method, "lexicon-tiebreak"))
})

test_that("a mask+lexicon code table is not eligible for the tie-break", {
  # 3 of these 6 random 5-digit numbers sit inside the county-FIPS table
  # (confirm 0.50, leak 0). That is coincidence, not under-coverage: the mask
  # carried the signal and the lexicon is a membership test. Must not route
  # geographic. Guarded twice over -- match_kind and tie_min_n.
  r <- guess_data_type(c("12309", "88421", "55012", "73418", "29100",
                         "61234"), seed = 1L)$route
  expect_false(isTRUE(r$semantic_type == "geographic"))
  expect_false(identical(r$router_method, "lexicon-tiebreak"))
})

test_that("tie_min_n keeps the tie-break out of short columns", {
  short <- surnames_200[1:12]
  r <- guess_data_type(short, seed = 1L, n_sample = 200)$route
  expect_false(identical(r$router_method, "lexicon-tiebreak"))
  # and it fires again once the column is long enough
  r2 <- guess_data_type(surnames_200, seed = 1L, n_sample = 200,
                           tie_min_n = 30L)$route
  expect_equal(r2$router_method, "lexicon-tiebreak")
})

test_that("the tie-break never outranks a selective leaf", {
  # a clean ISO date column has a selective variant, so stage 1 wins outright
  # and stage 1a is never consulted.
  d <- format(as.Date("2020-01-01") + seq(0, 200, by = 3))
  r <- guess_data_type(d, seed = 1L)$route
  expect_equal(r$semantic_type, "calendar")
  expect_false(identical(r$router_method, "lexicon-tiebreak"))
})
