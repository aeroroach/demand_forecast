pre_diag <- function(trade_agg, con_loop, log_path) {
  
  prediag <- NULL
  
  for (i in 1:nrow(con_loop)) {
    
    # print(paste("========= Start running loop", i, "from total", nrow(con_loop)))
    
    # Filtering data for each loop
    brand <- con_loop$trade_product_brand[i]
    model <- con_loop$trade_product_model[i]
    trade_agg %>% 
      filter(trade_product_brand == brand,
             trade_product_model == model) -> model_agg
    
    # Filtering 75% observation since beginning
    age_min <- min(model_agg$age_week)
    age_max <- max(model_agg$age_week)
    range <- ceiling((age_max - age_min)*0.75)
    age_filter <- age_max - range
    
    model_agg %>% 
      filter(age_week >= age_filter) -> model_agg
    
    # Fitting poisson log link
    fitpois_log <- glm(sales ~ age_week,
                       family = poisson(link = "log"),
                       data = model_agg)
    
    model_agg$fitt_log <- fitpois_log$fitted.values
    
    # Fitting poisson log link
    # fitpois_lin <- glm(sales ~ age_week,
    #                    family = poisson(link = "identity"),
    #                    data = model_agg)
    # 
    # model_agg$fitt_lin <- fitpois_lin$fitted.values 
    
    # Initiate last boosting period
    model_agg %>% 
      filter(boosting_flag == 1) -> boost
    
    if (nrow(boost) != 0) {
      
      boost <- max(boost$age_week)
      
    } else { 
      
      boost <- 0
      
      }
    
    # Initiate RMSE
    res_log <- model_agg$sales - model_agg$fitt_log
    # res_lin <- model_agg$sales - model_agg$fitt_lin
    
    rmse_log <- sqrt(mean(res_log^2))
    # rmse_lin <- sqrt(mean(res_lin^2))
    
    # Writing log
    pre_model <- data.frame(loop_index = i, 
                            HS_brand = brand,
                            HS_model = model,
                            Age_week = age_max,
                            n = nrow(model_agg),
                            last_boost = boost,
                            sales_min = min(model_agg$sales),
                            sales_q1 = as.numeric(quantile(model_agg$sales, 0.25)),
                            sales_med = median(model_agg$sales),
                            sales_q3 = as.numeric(quantile(model_agg$sales, 0.75)),
                            sales_max = max(model_agg$sales),
                            RMSE_log = round(rmse_log, digits = 3)
                            )
    
    
    # pre_model <- data.frame(HS_brand = brand,
    #                         HS_model = model,
    #                         Age_week = age_max,
    #                         n = nrow(model_agg),
    #                         last_boost = boost,
    #                         sales_min = min(model_agg$sales),
    #                         sales_q1 = as.numeric(quantile(model_agg$sales, 0.25)),
    #                         sales_med = median(model_agg$sales),
    #                         sales_q3 = as.numeric(quantile(model_agg$sales, 0.75)),
    #                         sales_max = max(model_agg$sales),
    #                         RMSE_log = round(rmse_log, digits = 3),
    #                         rmse_lin = round(rmse_lin, digits = 3)
    #                         )
    
    prediag <- rbind(prediag, pre_model)
  }
  
  diag_path <- paste0(log_path, "pre_Diag.csv")
  write_csv(prediag, diag_path)
  
}