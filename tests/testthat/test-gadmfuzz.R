
test_that("fuzzy match core", {
  expected_results <- data.frame(
    national_stats = c("baba", "coucou", "kuku"),
    gadm = c("bobo", "coco", "kiki"),
    dist = c(1/3, 1/9, 1/3),
    stringsAsFactors = FALSE
  )
  dist_table <- fuzzy_string_match(c("baba", "coucou", "kuku"),
                                   c("bobo", "kiki", "coco"))
  expect_equal(dist_table, expected_results)
})

test_that("EGY", {
  egy_governorates <- unique(wheat_egypt$governorate)
  best_matches <- find_best_match(gadm_sf = EGY,
                                  subregion_names = egy_governorates)
  expect_snapshot(best_matches)
})

test_that("Detect proper gadm level", {
  level <- determine_level_gadm(gadm_country = EGY)
  expect_identical(level, 1L)
})
