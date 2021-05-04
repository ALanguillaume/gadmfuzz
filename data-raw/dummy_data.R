

governorates <- c("Alexandria", "Behera", "Gharbia", "Kafr-Elsheikh", "Dakahlia",
                  "Damietta", "Sharkia", "Ismailia", "Port Said", "Suez", "Menoufia",
                  "Qalyoubia", "Cairo", "Giza", "Beni Suef", "Fayoum", "Menia",
                  "Assuit", "Suhag", "Qena", "Luxor", "Aswan", "New valley", "Matruh",
                  "North Sinai", "South Sinai", "Noubaria")
wheat_yield_EGY <- data.frame(
  governorate = governorates,
  yield_tha = rnorm(length(governorates), 6, 1)
)
usethis::use_data(wheat_yield_EGY, overwrite = TRUE)

# download_gadm("EGY", path = "data-raw/", level = 1)
gadm36_EGY_1_sf <- readRDS("data-raw/gadm36_EGY_1_sf.rds")
usethis::use_data(gadm36_EGY_1_sf, overwrite = TRUE)
