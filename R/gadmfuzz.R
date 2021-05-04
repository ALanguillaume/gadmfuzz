

#' @importFrom stringi stri_trans_general
#' @noRd
to_Latin_ASCII <- function(string) {
  stringi::stri_trans_general(string, id = "Latin-ASCII")
}

#' Identify level of gadm polygon
#' @param gadm_country A sf object gadm polygon geometries for a given country.
#' @return An integer: 0, 1 or 2, representing level of the gadm polygon.
#' @importFrom stringr str_extract
#' @noRd
determine_level_gadm <- function(gadm_country_sf) {
  NAME_X <- grep("^NAME_\\d$", names(gadm_country_sf), value = TRUE)
  level_gadm <- max(as.integer(stringr::str_extract(NAME_X, "\\d")))
  return(level_gadm)
}

#' Get all English spellings of a given gadm polygon regions
#' @param gadm_country A sf object holding geometries for a given gadm country.
#' @importFrom purrr map reduce
#' @noRd
get_all_english_spellings <- function(gadm_country_sf) {
  level_gadm <- determine_level_gadm(gadm_country_sf)
  subregion_name_cols <- paste0(c("NAME_", "VARNAME_"), level_gadm)
  target_cols <- gadm_country_sf[, subregion_name_cols, drop = TRUE]
  target_cols <- purrr::map(target_cols, to_Latin_ASCII)
  combined_vector <- purrr::reduce(target_cols, function(x, y) paste(x, y, sep = "|"))
  combined_list <- strsplit(combined_vector, "\\|")
  return(combined_list)
}

# Sane default version of expand.grid()
expand_grid <- function(...) {
  expand.grid(..., KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
}

#' Perform fuzzy string
#' @import stringdist stringdist
#' @importFrom purrr map_dfr
#' @noRd
fuzzy_string_match_core <- function(regional_stats, gadm) {
  df_dist <- expand_grid(regional_stats = regional_stats, gadm = gadm)
  df_dist[["dist"]] <- stringdist::stringdist(df_dist$regional_stats, df_dist$gadm,
                                              method = "jw")
  l_df_dist <- split(df_dist, df_dist$gadm)
  df_dist_match <- purrr::map_dfr(l_df_dist, ~ .x[which.min(.x$dist), ])
  return(df_dist_match)
}


#' For a given entry perform fuzzy string matching against all subregion names
#'
#' @param gadm_entrie A character string
#' @param region_names A character vector
#'
#' @return A data.frame of with number of rows equals to
#' `length(gadm_entrie) x length(region_names)` containing the fuzzy string matching
#' scores.
#'
#' @importFrom purrr map_dfr
#' @noRd
compare_gadm_entrie_with_region_names <- function(gadm_entrie, region_names) {
  dist_table_df <- purrr::map_dfr(region_names,
                                  ~ fuzzy_string_match_core(regional_stats = .x,
                                                            gadm_entrie))
  return(dist_table_df)
}

# Iterate through each possible spelling of a gadm subregion.
# Results are stored into a list column.
# Each element of that list column is a data.frame containing fuzzy match scores.
#' @importFrom sf st_drop_geometry
#' @importFrom purrr map
#' @noRd
fuzzy_match_over_gadm_entries <- function(region_names, gadm_country_sf) {
  gadm <- sf::st_drop_geometry(gadm_country_sf)
  gadm[["all_NAMEs"]] <- get_all_english_spellings(gadm)
  l_dist_table_df <- purrr::map(gadm[["all_NAMEs"]],
                                ~ compare_gadm_entrie_with_region_names(gadm_entrie = .x,
                                                                        region_names))
  gadm$dist_table <- l_dist_table_df
  return(gadm)
}

#' @importFrom purrr map2_dfr
#' @noRd
add_corresponding_GID <- function(gadm) {
  gadm_id_region <- paste0("GID_", determine_level_gadm(gadm))
  dist_table_df <- purrr::map2_dfr(gadm[["dist_table"]], gadm[[gadm_id_region]],
                                   function(dist_table, id_region) {
                                     dist_table[["id_region"]] <- id_region
                                     return(dist_table)})
  return(dist_table_df)
}


#' @importFrom dplyr group_by filter ungroup
#' @importFrom rlang .data
#' @importFrom purrr map
#' @noRd
filter_best_match <- function(dist_table_df) {
  dist_table_by_ns <- dplyr::group_by(dist_table_df, .data$regional_stats)
  best_matches <- dplyr::filter(dist_table_by_ns, .data$dist == min(.data$dist))
  best_matches <- dplyr::ungroup(best_matches)
  best_matches[c("regional_stats", "gadm")] <-
    purrr::map(best_matches[c("regional_stats", "gadm")], as.character)
  return(best_matches)
}

#' Match GADM polygon entries with local region names
#'
#' Match GADM polygon entries with local region names provided in other data sets.
#' It does so using fuzzy string matching. It is especially useful for countries
#' not using the latin alphabet for which GADM provides a list of possible
#' transliterated English spellings.
#'
#' @param region_names A character vector holding the unique region names to be matched
#' against their GADM counterparts.
#' @param gadm_country_sf A sf object holding GADM geometries for a given country.
#' This must correspond to GADM level 1 or 2. That is geometries of sub-regions
#' not only country borders (GADM level 0).
#'
#' @return A tibble holding the fuzzy matching results with 4 columns:
#'
#' * `regional_stats`: The name of the regions in your data set.
#' * `gadm`: The best corresponding match among all possible GADM region names for the
#' country of interest.
#' * `dist`: The distance between each entry in `regional_stats` and `gadm`. This is unit less.
#' 0 correspond to a perfect match, 1 to a complete mismatch (no overlap).
#' * `id_region`: The GADM region id. This corresponds to `GID_{1|2}` in GADM polygons.
#'
#' @examples
#' egy_governorates <- unique(wheat_yield_EGY$governorate)
#' gadmfuzz::find_best_match(region_names = egy_governorates,
#'                           gadm_country_sf = gadm36_EGY_1_sf)
#'
#' @export
find_best_match <- function(region_names, gadm_country_sf) {
  gadm <- fuzzy_match_over_gadm_entries(region_names, gadm_country_sf)
  dist_table_df <- add_corresponding_GID(gadm)
  best_matches <- filter_best_match(dist_table_df)
  return(best_matches)
}
