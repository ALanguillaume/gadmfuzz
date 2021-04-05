
#' @importFrom stringi stri_trans_general
to_Latin_ASCII <- function(string) {
  stringi::stri_trans_general(string, id = "Latin-ASCII")
}

#' Identify level of gadm polygon
#' @param gadm_country [sf object] gadm polygon geometries for a given country.
#' @return [integer] 0, 1 or 2, representing level of the gadm polygon.
#' @importFrom stringr str_extract
determine_level_gadm <- function(gadm_country) {
  NAME_X <- grep("^NAME_\\d$", names(gadm_country), value = TRUE)
  level_gadm <- max(as.integer(stringr::str_extract(NAME_X, "\\d")))
  return(level_gadm)
}

#' Get all English spellings of a given gadm polygon regions
#' @param gadm_country A sf object holding geometries for a given gadm country.
#' @importFrom purrr map reduce
#' @export
get_all_english_spellings <- function(gadm_country) {
  level_gadm <- determine_level_gadm(gadm_country)
  subregion_name_cols <- paste0(c("NAME_", "VARNAME_"), level_gadm)
  target_cols <- gadm_country[, subregion_name_cols, drop = TRUE]
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
fuzzy_string_match <- function(national_stats, gadm) {
  df_dist <- expand_grid(national_stats = national_stats, gadm = gadm)
  df_dist[["dist"]] <- stringdist::stringdist(df_dist$national_stats, df_dist$gadm,
                                              method = "jw")
  l_df_dist <- split(df_dist, df_dist$gadm)
  df_dist_match <- purrr::map_dfr(l_df_dist, ~ .x[which.min(.x$dist), ])
  return(df_dist_match)
}

#' @importFrom dplyr group_by filter ungroup
#' @importFrom purrr map
filter_best_match <- function(dist_table_df) {
  dist_table_by_ns <- dplyr::group_by(dist_table_df, national_stats)
  best_matches <- dplyr::filter(dist_table_by_ns, dist == min(dist))
  best_matches <- dplyr::ungroup(best_matches)
  best_matches[c("national_stats", "gadm")] <-
    purrr::map(best_matches[c("national_stats", "gadm")], as.character)
  return(best_matches)
}

add_corresponding_GID <- function(gadm) {
  gadm_id_subregion <- paste0("GID_", determine_level_gadm(gadm))
  dist_table_df <- purrr::map2_dfr(gadm$dist_table, gadm[[gadm_id_subregion]],
                    function(dist_table, id_subregion) {
                      dist_table[["id_subregion"]] <- id_subregion
                      return(dist_table)})
  return(dist_table_df)
}

#' @importFrom sf st_drop_geometry
#' @importFrom purrr map map_dfr map2_dfr
#' @export
find_best_match <- function(gadm_sf, subregion_names) {

  gadm <- sf::st_drop_geometry(gadm_sf)
  gadm[["all_NAMEs"]] <- get_all_english_spellings(gadm)


  gadm$dist_table <-
    purrr::map(gadm[["all_NAMEs"]],
               function(gadm_entries) {
                 purrr::map_dfr(subregion_names,
                                fuzzy_string_match,
                                gadm_entries)
               })
  dist_table_df <- add_corresponding_GID(gadm)
  best_matches <- filter_best_match(dist_table_df)
  return(best_matches)
}
