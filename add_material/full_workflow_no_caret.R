# This script is used to demonstrate the implementation of a full worflow "by hand".
# Used in Care Session 2.

set.seed(1982)

# Read and wrangle data ---------------------
# (no pre-processing!). Here, no wrangling done (cleaning, variable selection, etc.)
# df <- read.csv(paste0(here::here(), "/data/df_daily_exercise_supervisedmlii.csv"))

# alternative
df <- read_csv(paste0(here::here(), "/data/FLX_CH-Dav_FLUXNET2015_FULLSET_DD_1997-2014_1-3.csv")) |>  
  
  # select only the variables we are interested in
  dplyr::select(TIMESTAMP,
                GPP_NT_VUT_REF,    # the target
                ends_with("_QC"),  # quality control info
                ends_with("_F"),   # includes all all meteorological covariates
                -contains("JSB")   # weird useless variable
  ) |>
  
  # convert to a nice date object
  dplyr::mutate(TIMESTAMP = lubridate::ymd(TIMESTAMP)) |>
  
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
  dplyr::select(-ends_with("_QC")) |> 
  drop_na()

# Split data into train and test ---------------------

# Specify formula and pre-processing recipe ---------------------
# (allocate “roles” to variables)
nam_target <- "GPP_NT_VUT_REF"
nams_predictors <- c("TA_F", "SW_IN_F", "VPD_F")

# Hyperparameter loop ---------------------
vec_k <- c(2, 5, 10, 15, 20, 25, 30, 35, 40, 60, 100, 200, 300)

# specify number of cross-validation folds
n_folds <- 5

# initialise loss across resamples, to be kept for each hyperparameter choice
loss_avg <- c()

for (i_k in seq(length(vec_k))){

  # re-shuffle rows in data frame (not required)
  df <- df[sample(nrow(df)),]

  # create folds:
  # determine row indices to be allocated to each fold
  # each fold takes in 1/n_folds of the total number of rows
  nrows_per_fold <- ceiling(nrow(df) / n_folds)
  idx <- rep(seq(1:n_folds), each = nrows_per_fold)
  resample_folds <- split(1:nrow(df), idx[1:nrow(df)])  # yields a list of vectors containing the row indices

  ## resample loop ---------------------
  # initialise vector of loss per resample
  loss_vec <- c()
  
  for (i_resample in seq(n_folds)){

    ## Split into validation and (remaining) train set ---------------------
    # validation set
    df_valid <- df[resample_folds[[i_resample]], c(nam_target, nams_predictors)]
    
    ## remaining training set
    df_train <- df[-resample_folds[[i_resample]], c(nam_target, nams_predictors)]

    ## Apply pre-processing ---------------------
    # center and scale based on training data parameters
    mean_byvar <- c()
    sd_byvar <- c()
    df_train_cs <- df_train * NA
    df_valid_cs <- df_valid * NA
    
    # center and scale each predictor
    for (ivar in nams_predictors){
      
      # determine mean and sd for centering and scaling
      mymean   <- mean(df_train[[ivar]], na.rm = TRUE)
      mysd     <- sd(df_train[[ivar]], na.rm = TRUE)
      
      # center and scale training data
      df_train_cs[,ivar] <- df_train[[ivar]] - mymean
      df_train_cs[,ivar] <- df_train_cs[[ivar]] / mysd
      
      # center and scale validation data 
      # important: use parameters (mean and sd) determined on training data
      df_valid_cs[,ivar] <- df_valid[[ivar]] - mymean
      df_valid_cs[,ivar] <- df_valid_cs[[ivar]] / mysd
    }
    
    # add unmodified target variable
    df_valid_cs[,nam_target] <- df_valid[[nam_target]] 
    df_train_cs[,nam_target] <- df_train[[nam_target]] 

    ## Fit model on train set ---------------------
    # train using the scaled training data
    mod <- caret::knnreg(df_train_cs[,nams_predictors], 
                         df_train_cs[,nam_target], 
                         k = vec_k[i_k]
                         )

    ## Predict on validation set ---------------------
    # on the scaled validation set!
    df_valid_cs$pred <- predict(mod, newdata = df_valid_cs[,nams_predictors])

    ## Get loss from prediction on validation set ---------------------
    # Here, calculate mean absolute error on validation data
    loss_vec[i_resample] <- mean(abs(df_valid_cs$pred - df_valid_cs[,nam_target]), na.rm = TRUE)

  }

  # Average loss across resamples ---------------------
  loss_avg[i_k] <- mean(loss_vec, na.rm = TRUE)

}

# Pick best hyperparameter based on average loss across resamples ---------------------
best_k <- vec_k[which.min(loss_avg)]

# print result
print(paste("The best choice of hyperparameter k is:", best_k))

# visualise
library(ggplot2)
df_plot <- tibble(
  k = vec_k,
  loss = loss_avg
  )

ggplot(aes(k, loss), data = df_plot) +
  geom_point() +
  geom_line() +
  theme_classic() +
  labs(title = "Validation loss", subtitle = "Mean absolute error, mean across folds")
