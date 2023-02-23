library(ecmwfr)

#---- netcdf ERA5 data for switzerland ----

request <- list(
  variable = "2m_temperature",
  year = "2022",
  month = "01",
  day = "01",
  time = "12:00",
  area = c(
    48,
    5,
    44,
    12
    ),
  format = "netcdf",
  dataset_short_name = "reanalysis-era5-land",
  target = "demo_data.nc"
)

ecmwfr::wf_request(
  request,
  user = "2088",
  path = "./data/"
)

#---- convert data to tif with some different pixels ----

r <- terra::rast("data/demo_data.nc")
r <- r -273.15
r[10,] <- NA
terra::units(r) <- "C"
terra::writeRaster(
  r,
  "data/demo_data.tif",
  overwrite = TRUE
  )