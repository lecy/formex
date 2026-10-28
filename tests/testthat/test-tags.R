# tags detector: a flat delimited set (datagoodr starwars report: list columns
# collapsed to "a|b|c" were unrecognized).

test_that("is_tags recognizes a delimited set, not prose or single values", {
  expect_equal(is_tags(c("Volunteer;Donor;Board", "a|b|c", "Staff|Board")), rep(TRUE, 3))
  expect_equal(is_tags(c("hello", "a;", "")), rep(FALSE, 3))
  expect_true(is.na(is_tags(NA)))
})

test_that("as_tags normalizes the delimiter to ';' and trims members", {
  expect_equal(fx_transform(c("Staff|Board", "a; b ; c", "nope"), "{{ as_tags }}"),
               c("Staff;Board", "a;b;c", NA))
})

test_that("a delimited column routes to categorical/tags", {
  r <- guess_data_type(c("Volunteer;Donor;Board","Donor;Board","Staff|Volunteer","Board;Donor","Volunteer;Staff"))$route
  expect_equal(r$data_type, "categorical")
  expect_equal(r$semantic_type, "tags")
  expect_equal(r$depth, 4L)
  # the datagoodr case: a pipe-collapsed list
  expect_equal(guess_data_type(c("a|b|c","d|e","f|g|h","a|c"))$route$semantic_type, "tags")
})
