library(readr)

#--- limited flux data set ----

# creating a subset of the original data
# to limit data overhead for examples
hhdf <- read_csv("./data-raw/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2014_1-3.csv")

# reduce to the first three years only
hhdf <- hhdf[1:(3*2*24*365+48),]

# write to file
write_csv(hhdf, file = "./data/FLX_CH-Lae_FLUXNET2015_FULLSET_HH_2004-2006.csv")

# Create daily fluxes data for exercise in Chapter Supervised ML II ------------
daily_fluxes <- readr::read_csv("./data/FLX_CH-Dav_FLUXNET2015_FULLSET_DD_1997-2014_1-3.csv") |>  
  
  # select only the variables we are interested in
  dplyr::select(TIMESTAMP,
                GPP_NT_VUT_REF,    # the target
                ends_with("_QC"),  # quality control info
                ends_with("_F"),   # includes all all meteorological covariates
                -contains("JSB")   # weird useless variable
  ) |>
  
  # convert to a nice date object
  dplyr::mutate(TIMESTAMP = ymd(TIMESTAMP)) |>
  
  # set all -9999 to NA
  dplyr::mutate(across(where(is.numeric), ~na_if(., -9999))) |> 
  
  # retain only data based on >=80% good-quality measurements
  # overwrite bad data with NA (not dropping rows)
  dplyr::mutate(GPP_NT_VUT_REF = ifelse(NEE_VUT_REF_QC < 0.8, NA, GPP_NT_VUT_REF),
                TA_F           = ifelse(TA_F_QC        < 0.8, NA, TA_F),
                SW_IN_F        = ifelse(SW_IN_F_QC     < 0.8, NA, SW_IN_F),
                LW_IN_F        = ifelse(LW_IN_F_QC     < 0.8, NA, LW_IN_F),
                VPD_F          = ifelse(VPD_F_QC       < 0.8, NA, VPD_F),
                PA_F           = ifelse(PA_F_QC        < 0.8, NA, PA_F),
                P_F            = ifelse(P_F_QC         < 0.8, NA, P_F),
                WS_F           = ifelse(WS_F_QC        < 0.8, NA, WS_F)) |> 
  
  # drop QC variables (no longer needed)
  dplyr::select(-ends_with("_QC"))

nam_target <- "GPP_NT_VUT_REF"
nams_predictors <- c("TA_F", "SW_IN_F", "VPD_F")

df <- daily_fluxes |> 
  select(all_of(c("TIMESTAMP", nam_target, nams_predictors))) |> 
  drop_na() |> 
  as.data.frame()

write_csv(df, file = "./data/df_daily_exercise_supervisedmlii.csv")

# Create data for stepwise regression ------------------------------------------
vec_files <- list.files(here::here("data/"), pattern = "_FLUXNET2015_FULLSET_DD_", full.names = TRUE)
list_df <- purrr:::map(as.list(vec_files), ~readr::read_csv(.))
names(list_df) <- vec_files

clean_fluxnet_dd <- function(df){
  
  df %>%
    
    ## select only the variables we're interested in
    select(starts_with("TIMESTAMP"),
           ends_with("_F"),
           ends_with("_F_MDS"),
           # ends_with("_ERA"),
           starts_with("_SWC_F_MDS"),
           CO2_F_MDS,
           PPFD_IN,
           GPP_NT_VUT_REF,
           NEE_VUT_REF_QC,
           USTAR,
           -starts_with("G_"),
           -starts_with("LE_"),
           -starts_with("H_"),
           -contains("JSB")
    ) %>%
    
    ## convert to a nice date object
    mutate(TIMESTAMP = lubridate::ymd(TIMESTAMP)) %>%
    
    ## not setting heavily gapfilled data to zero
    
    ## set all -9999 to NA
    dplyr::mutate(across(where(is.numeric), ~na_if(., -9999))) |> 
    
    # drop NAs
    # drop_na() |>
    
    ## filter bad data (at least 80% must be measured or good quality gapfilled)
    mutate(GPP_NT_VUT_REF = ifelse(NEE_VUT_REF_QC < 0.8, NA, GPP_NT_VUT_REF)) |>
    
    ## drop QC variables (no longer needed), except NEE_VUT_REF_QC
    select(-ends_with("_QC"))
  
}

df <- purrr::map(list_df, ~clean_fluxnet_dd(.)) |>
  dplyr::bind_rows(.id = "siteid") |>
  dplyr::mutate(siteid = str_sub(siteid, start = 39, end = 44))

readr::write_csv(df, paste0(here::here(), "/data/df_for_stepwise_regression.csv"))
                 
                 
                 
                 