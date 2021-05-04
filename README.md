
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gadmfuzz

<!-- badges: start -->
<!-- badges: end -->

The goal of `{gadmfuzz}` is to match [GADM](https://gadm.org/index.html)
polygon entries with local region names provided in other data sets. It
does so using fuzzy string matching. It is especially useful for
countries not using the latin alphabet for which GADM provides a list of
possible transliterated English spellings.

> !!WIP!!: This is very much Work in Progress and still needs to be
> tested and documented properly.

## Installation

``` r
remotes::install_github("ALanguillaume/gadmfuzz")
```

## Example

``` r
library(gadmfuzz)
```

Let’s take Egypt as an example. Governorate names can have a fair number
of different spellings when transliterated to English. GADM provides a
whole bunch of them:

``` r
head(gadm36_EGY_1_sf[["VARNAME_1"]])
#> [1] "Al Daqahliyah|Dacahlia|Dagahlia|Dakahlieh|Dakahliya|Dakalieh|Daqalīya|Dakahlia|Dekahlia"
#> [2] "Mar Rojo|Mar Vermelho|Mer Rouge|Red Sea"                                                
#> [3] "Beheira|Behera|El Buhayra|Béhéra"                                                       
#> [4] "El Faiyum|el Fayoum|Faium|Faiyūm|Fayum|Fayoum|Fayyum"                                   
#> [5] "al-Garbīyah|El Gharbiya|Garbia|Gharbieh|Gharbīya|Gharbia"                               
#> [6] "Alexandria|Alexandrie|El Iskandariya"
```

…But how to match those with a particular entry of the wheat yield data
set you have ?

``` r
(egy_governorates <- unique(wheat_yield_EGY$governorate))
#>  [1] "Alexandria"    "Behera"        "Gharbia"       "Kafr-Elsheikh"
#>  [5] "Dakahlia"      "Damietta"      "Sharkia"       "Ismailia"     
#>  [9] "Port Said"     "Suez"          "Menoufia"      "Qalyoubia"    
#> [13] "Cairo"         "Giza"          "Beni Suef"     "Fayoum"       
#> [17] "Menia"         "Assuit"        "Suhag"         "Qena"         
#> [21] "Luxor"         "Aswan"         "New valley"    "Matruh"       
#> [25] "North Sinai"   "South Sinai"   "Noubaria"
```

Use `gadmfuzz::find_best_match()` to find out:

``` r
best_matches <- gadmfuzz::find_best_match(region_names = egy_governorates,
                                          gadm_country_sf = gadm36_EGY_1_sf)
```

``` r
best_matches
#> # A tibble: 29 x 4
#>    regional_stats gadm        dist id_region
#>    <chr>          <chr>      <dbl> <chr>    
#>  1 Dakahlia       Dakahlia   0     EGY.1_1  
#>  2 Behera         Behera     0     EGY.3_1  
#>  3 Fayoum         Fayoum     0     EGY.4_1  
#>  4 Gharbia        Gharbia    0     EGY.5_1  
#>  5 Noubaria       Garbia     0.281 EGY.5_1  
#>  6 Alexandria     Alexandria 0     EGY.6_1  
#>  7 Ismailia       Ismailia   0     EGY.7_1  
#>  8 Giza           Giza       0     EGY.8_1  
#>  9 Menoufia       Menoufia   0     EGY.9_1  
#> 10 Menia          Menia      0     EGY.10_1 
#> # … with 19 more rows
```
