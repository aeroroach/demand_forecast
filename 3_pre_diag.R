pre_diag <- function(trade_agg, con_loop, log_path) {
  
  prediag <- NULL
  
  trade_agg %>% 
    group_by(trade_product_brand, trade_product_model, age_week) %>% 
    summarise(sales = sum(sales)) -> trade_pre
  
  for (i in 1:nrow(con_loop)) {
    
    # print(paste("========= Start running loop", i, "from total", nrow(con_loop)))
    
    # Filtering data for each loop
    brand <- con_loop$trade_product_brand[i]
    model <- con_loop$trade_product_model[i]
    trade_pre %>% 
      filter(trade_product_brand == brand,
             trade_product_model == model) %>% 
      arrange(age_week) -> model_agg
    
    # Filtering 75% observation since beginning
    age_min <- min(model_agg$age_week)
    age_max <- max(model_agg$age_week)
    
    min_row <- nrow(model_agg) - floor(nrow(model_agg) * 0.75)
    model_agg <- model_agg[min_row:nrow(model_agg),]
    
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
#     model_agg$fitt_lin <- fitpois_lin$fitted.values
    
    # Initiate measurement
    res_log <- model_agg$sales - model_agg$fitt_log
    # res_lin <- model_agg$sales - model_agg$fitt_lin
    
    rmse_log <- sqrt(mean(res_log^2))
    # rmse_lin <- sqrt(mean(res_lin^2))
    mape_log <- mean(abs(res_log/model_agg$fitt_log)*100)
    # mape_lin <- mean(abs(res_log/model_agg$fitt_lin)*100)
    
    # Writing log
    pre_model <- data.frame(HS_brand = brand,
                            HS_model = model,
                            Age_week = age_max,
                            n = nrow(model_agg),
                            sales_min = min(model_agg$sales),
                            sales_q1 = as.numeric(quantile(model_agg$sales, 0.25)),
                            sales_med = median(model_agg$sales),
                            sales_q3 = as.numeric(quantile(model_agg$sales, 0.75)),
                            sales_max = max(model_agg$sales),
                            rmse_log = round(rmse_log, digits = 3),
                            mape_log = round(mape_log, digits = 3)
                            # rmse_lin = round(rmse_lin, digits = 3),
                            # mape_lin = round(mape_lin, digits = 3)
                            )
    
    prediag <- rbind(prediag, pre_model)
  }
  
  diag_path <- paste0(log_path, "pre_Diag.csv")
  write_csv(prediag, diag_path)
  
}