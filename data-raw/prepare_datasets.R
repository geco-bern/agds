library(readr)

hhdf <- read_csv("./data-raw/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2014_1-3.csv")

## reduce to the first three years only
hhdf <- hhdf[1:(3*2*24*365+48),]

write_csv(hhdf, file = "./data/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2006.csv")
