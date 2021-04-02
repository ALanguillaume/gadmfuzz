

governorates <- c("Alexandria", "Behera", "Gharbia", "Kafr-Elsheikh", "Dakahlia",
                  "Damietta", "Sharkia", "Ismailia", "Port Said", "Suez", "Menoufia",
                  "Qalyoubia", "Cairo", "Giza", "Beni Suef", "Fayoum", "Menia",
                  "Assuit", "Suhag", "Qena", "Luxor", "Aswan", "New valley", "Matruh",
                  "North Sinai", "South Sinai", "Noubaria")

wheat_egypt <- data.frame(
  governorate = governorates,
  yield_tha = rnorm(length(governorates), 6, 1)
)

usethis::use_data(wheat_egypt, overwrite = TRUE)
