
#' Download GADM country border polygons
#'
#' Download GADM country border polygons, by default at highest scale possible,
#' level 0. It is also possible to specify at which gadm level the polygons should
#' correspond to.
#'
#' @param iso3  A character, iso3c code for the country of interest.
#' @param path A character string, path of the directory where files should be saved.
#' @param level A integer (0, 1, or 2), corresponding to the gadm level:
#' 0 corresponds to country borders while 1 and 2 correspond to administrative units
#' within the country:
#' * 1 to biggest administrative units for a given country.
#' * 2 to smallest available administrative units for a given country.
#'
#' @importFrom utils download.file
#'
#' @export

download_gadm <- function(iso3, path, level = 0) {
  base_url <- "https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36"
  target_url <- paste(base_url, iso3, level, "sf.rds", sep = "_")
  destination_file_name <- paste("gadm36", iso3, level, "sf.rds", sep = "_")
  destination_file <- file.path(path, destination_file_name)
  utils::download.file(url = target_url, destfile = destination_file)
}
