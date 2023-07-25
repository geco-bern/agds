#' Evaluate model performance
#'
#' @param mod the model formulation
#' @param df_train the training data
#' @param df_test the testing data
#' @param return_metrics the metrics / figures returned
#'
#' @return model metrics
 
eval_model <- function(mod, df_train, df_test, return_metrics = FALSE){
  
  
  # Require caret to avoid errors if a caret-based model is entered without having caret loaded globally
  if (!require("caret", character.only = TRUE)) {
    stop("Error: Could not load the library {caret}. Please install it and try again.")
  }
  
  # Require magrittr because script uses %>% pipe 
  if (!require("magrittr", character.only = TRUE)) {
    stop("Error: Could not load the library {caret}. Please install it and try again.")
  }
  
  # add predictions to the data frames----
  df_train <- df_train %>% 
    drop_na() %>%  # magrittr pipe necessary here for the dot ('.') evaluation
    mutate(fitted =  predict(mod, newdata = .))
  
  df_test <- df_test %>% 
    drop_na() %>% 
    mutate(fitted =  predict(mod, newdata = .))
  
  # get metrics tables----
  metrics_train <- df_train %>% 
    yardstick::metrics(GPP_NT_VUT_REF, fitted)
  
  metrics_test <- df_test %>% 
    yardstick::metrics(GPP_NT_VUT_REF, fitted)
  
  if (return_metrics){
    
    return(list(train = metrics_train, test = metrics_test))
    
  } else {
    # extract values from metrics tables----
    rmse_train <- metrics_train %>% 
      filter(.metric == "rmse") %>% 
      pull(.estimate)
    rsq_train <- metrics_train %>% 
      filter(.metric == "rsq") %>% 
      pull(.estimate)
    
    rmse_test <- metrics_test %>% 
      filter(.metric == "rmse") %>% 
      pull(.estimate)
    rsq_test <- metrics_test %>% 
      filter(.metric == "rsq") %>% 
      pull(.estimate)
    
    # visualise as a scatterplot----
    # adding information of metrics as sub-titles
    gg1 <- df_train %>% 
      ggplot(aes(GPP_NT_VUT_REF, fitted)) +
      geom_point(alpha = 0.3) +
      geom_smooth(method = "lm", se = FALSE, color = "red") +
      geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
      labs(subtitle = bquote( italic(R)^2 == .(format(rsq_train, digits = 2)) ~~
                                RMSE == .(format(rmse_train, digits = 3))),
           title = "Training set") +
      theme_classic()
    
    gg2 <- df_test %>% 
      ggplot(aes(GPP_NT_VUT_REF, fitted)) +
      geom_point(alpha = 0.3) +
      geom_smooth(method = "lm", se = FALSE, color = "red") +
      geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
      labs(subtitle = bquote( italic(R)^2 == .(format(rsq_test, digits = 2)) ~~
                                RMSE == .(format(rmse_test, digits = 3))),
           title = "Test set") +
      theme_classic()
    
    out <- cowplot::plot_grid(gg1, gg2)
    
    return(out) 
  }
}
