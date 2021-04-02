test_that("EGY", {

  EGY$all_NAMEs <- get_all_english_spellings(EGY)

  egy_governorates <- unique(wheat_egypt$governorate)
  best_matches <- find_best_match(gadm_sf = EGY,
                                  gadm_id_subregion = "GID_1",
                                  gadm_entries_list = "all_NAMEs",
                                  subregion_names = egy_governorates)
  expect_snapshot(best_matches)
})
