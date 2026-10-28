# Named-color detector + leaf: fixes color-word columns leaking to geographic
# (datagoodr starwars report: hair_color / eye_color -> geographic).

test_that("is_color_name recognizes color words, not places", {
  expect_equal(is_color_name(c("Brown", "hazel", "blond", "AUBURN")), rep(TRUE, 4))
  expect_equal(is_color_name(c("Chicago", "xzqwt", "")), rep(FALSE, 3))
  expect_true(is.na(is_color_name(NA)))
})

test_that("as_color_name stabilizes to a lowercased color word, NA otherwise", {
  expect_equal(fx_transform(c("Blond", "Brown", "Chicago"), "{{ as_color_name }}"),
               c("blond", "brown", NA))
})

test_that("color-word columns route to color/color_name, not geographic", {
  hair <- guess_data_type(c("blond","brown","none","brown","white","black"))$route
  expect_equal(hair$data_type, "text")
  expect_equal(hair$semantic_type, "color_name")
  eye <- guess_data_type(c("blue","yellow","brown","brown","blue","hazel"))$route
  expect_equal(eye$semantic_type, "color_name")
})

test_that("a real city column is unaffected (still place, not color)", {
  r <- guess_data_type(c("Chicago","Boston","Austin","Denver","Miami","Seattle"))$route
  expect_equal(r$semantic_type, "place")
})
