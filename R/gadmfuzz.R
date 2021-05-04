
#' @importFrom stringi stri_trans_general
to_Latin_ASCII <- function(string) {
  stringi::stri_trans_general(string, id = "Latin-ASCII")
}

#' Identify level of gadm polygon
#' @param gadm_country [sf object] gadm polygon geometries for a given country.
#' @return [integer] 0, 1 or 2, representing level of the gadm polygon.
#' @importFrom stringr str_extract
determine_level_gadm <- function(gadm_country_sf) {
  NAME_X <- grep("^NAME_\\d$", names(gadm_country_sf), value = TRUE)
  level_gadm <- max(as.integer(stringr::str_extract(NAME_X, "\\d")))
  return(level_gadm)
}

#' Get all English spellings of a given gadm polygon regions
#' @param gadm_country A sf object holding geometries for a given gadm country.
#' @importFrom purrr map reduce
#' @export
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
#' @param gadm_entrie [character vector]
#' @param region_names
#'
#' @return A data.frame of with number of rows equals to
#' `length(gadm_entrie) x length(region_names)` containing the fuzzy string matching
#' scores.
#'
#' @importFrom purrr map_dfr
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
add_corresponding_GID <- function(gadm) {
  gadm_id_region <- paste0("GID_", determine_level_gadm(gadm))
  dist_table_df <- purrr::map2_dfr(gadm[["dist_table"]], gadm[[gadm_id_region]],
                                   function(dist_table, id_region) {
                                     dist_table[["id_region"]] <- id_region
                                     return(dist_table)})
  return(dist_table_df)
}


#' @importFrom dplyr group_by filter ungroup
#' @importFrom purrr map
filter_best_match <- function(dist_table_df) {
  dist_table_by_ns <- dplyr::group_by(dist_table_df, regional_stats)
  best_matches <- dplyr::filter(dist_table_by_ns, dist == min(dist))
  best_matches <- dplyr::ungroup(best_matches)
  best_matches[c("regional_stats", "gadm")] <-
    purrr::map(best_matches[c("regional_stats", "gadm")], as.character)
  return(best_matches)
}


#' @export
find_best_match <- function(region_names, gadm_country_sf) {
  gadm <- fuzzy_match_over_gadm_entries(region_names, gadm_country_sf)
  dist_table_df <- add_corresponding_GID(gadm)
  best_matches <- filter_best_match(dist_table_df)
  return(best_matches)
}
