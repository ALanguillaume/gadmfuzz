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
