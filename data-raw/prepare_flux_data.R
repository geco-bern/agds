library(readr)

#--- limited flux data set ----

# creating a subset of the original data
# to limit data overhead for examples
hhdf <- read_csv("./data-raw/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2014_1-3.csv")

# reduce to the first three years only
hhdf <- hhdf[1:(3*2*24*365+48),]

# write to file
write_csv(hhdf, file = "./data/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2006.csv")
