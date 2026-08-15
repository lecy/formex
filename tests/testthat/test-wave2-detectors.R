# Contract tests for wave 2: fiscal year, GeoJSON, WKB/EWKB, and JSON.
# Fixture-independent, so they hold before data-raw/build_test_cases.R is re-run.

test_that("is_fiscal_year matches FY-labelled years and spans, not bare years", {
  expect_true(all(is_fiscal_year(c("FY2019", "FY19", "FY 2020", "FY2019-20",
                                   "FY2019/2020", "fy2021"))))
  expect_false(is_fiscal_year("2019"))     # bare year -- intentionally excluded
  expect_false(is_fiscal_year("FY"))       # no digits
  expect_false(is_fiscal_year("FY201"))    # odd-width year
  expect_true(is.na(is_fiscal_year(NA)))
})

test_that("is_geojson matches GeoJSON objects, not plain JSON", {
  expect_true(all(is_geojson(c(
    '{"type":"Point","coordinates":[30,10]}',
    '{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,0]]]}',
    '{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{}}',
    '{"type":"FeatureCollection","features":[]}'))))
  expect_false(is_geojson('{"a":1,"b":2}'))          # JSON but not GeoJSON
  expect_false(is_geojson('{"type":"Widget"}'))      # non-geo type, no payload
  expect_true(is.na(is_geojson(NA)))
})

test_that("is_wkb matches hex WKB/EWKB, rejects same-length hash hex", {
  expect_true(all(is_wkb(c(
    "0101000000000000000000f03f000000000000f03f",           # LE point
    "00000000013ff00000000000003ff0000000000000",           # BE point
    "0101000020e6100000000000000000f03f000000000000f03f"))))# EWKB point + SRID
  expect_false(is_wkb(strrep("a", 64)))   # SHA-256-shaped hex, bad type field
  expect_false(is_wkb("0201000000"))      # bad byte-order flag
  expect_true(is.na(is_wkb(NA)))
})

test_that("is_json matches objects and arrays", {
  expect_true(all(is_json(c('{"a":1}', '[1,2,3]', '{"k":{"x":1}}', '["a","b"]'))))
  expect_false(is_json("not json"))
  expect_false(is_json("{}"))             # no member -> not claimed
  expect_true(is.na(is_json(NA)))
})

# --- integration: routing + specificity (geojson beats loose json) -----------

test_that("guess_data_type routes GeoJSON to geometry, plain JSON to serialized", {
  g_geo <- guess_data_type(c('{"type":"Point","coordinates":[30,10]}',
                             '{"type":"Point","coordinates":[1,2]}',
                             '{"type":"LineString","coordinates":[[0,0],[1,1]]}'),
                           name = "geom")
  expect_equal(g_geo$guess, "geojson")
  expect_equal(unname(g_geo$ontology[["data_class"]]), "geometry")

  g_json <- guess_data_type(c('{"a":1,"b":2}', '{"x":10,"y":20}',
                              '{"id":3,"ok":true}'), name = "payload")
  expect_equal(g_json$guess, "json")
  expect_equal(unname(g_json$ontology[["data_class"]]), "serialized_text")
})

test_that("guess_data_type types an FY column as a fiscal year", {
  g <- guess_data_type(c("FY2018", "FY2019", "FY2020", "FY2021"),
                       name = "fiscal_year")
  expect_equal(g$guess, "fiscal_year")
  expect_equal(unname(g$ontology[["data_type"]]),  "temporal")
  expect_equal(unname(g$ontology[["data_class"]]), "year")
})
