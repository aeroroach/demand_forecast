HS_forecast <- function(trade_agg, con_loop, log_path) {
  
  lambda <- NULL
  log_skip <- NULL
  log_ML <- NULL
  
  for (i in 1:nrow(con_loop)) {
    
    # Handling error
    tryCatch({
    
    # Getting brand & model name
    brand <- con_loop$trade_product_brand[i]
    model <- con_loop$trade_product_model[i]
    sub_type <- con_loop$product_subtype[i]
    
    print(paste("========= Progress", i, "/", nrow(con_loop), "::", brand, model, sub_type))
    
    # Force error to test function
    # if (i==7) stop("Testing error")
      
    # Filtering selected HS model
    training_set <- trade_agg$train
    test_set <- trade_agg$test
    
    # print(paste("=========", brand, model, "Training stage"))
    
    training_set %>% 
      filter(trade_product_brand == brand,
             trade_product_model == model, 
             product_subtype == sub_type) %>% 
      ungroup() %>% 
      select(-trade_product_brand, -trade_product_model, -product_subtype, -range_week, -index) -> training_set
    
    test_set %>% 
      filter(trade_product_brand == brand,
             trade_product_model == model, 
             product_subtype == sub_type) %>% 
      ungroup() %>% 
      select(-trade_product_brand, -trade_product_model, -product_subtype, -range_week, -index) -> test_set
    
    # Check discount level
    # backup_discount <- unique(training_set$dis_cat)
    dis_level <- length(unique(training_set$dis_cat))
    dis_check <- unique(test_set$dis_cat) %in% unique(training_set$dis_cat)
    
    if (dis_level > 1 & all(dis_check) == F) {
      
      fil_dis <- unique(test_set$dis_cat)[dis_check]
      test_set %>% 
        filter(dis_cat %in% fil_dis) -> test_set
      
    } else if (dis_level == 1) {
      
      training_set %>%
        ungroup() %>% 
        select(-dis_cat) -> training_set
      
      test_set %>% 
        ungroup() %>% 
        select(-dis_cat) -> test_set
      
    }
    
    # Check boost level
    boost_level <- length(unique(training_set$boosting_flag))
    
    if (boost_level == 1) {
      training_set %>% 
        select(-boosting_flag) -> training_set
      
      test_set %>% 
        select(-boosting_flag) -> test_set
    }
    
    # Fitting initial poisson  
    fitpois <- glm(sales ~ .,
                   family = "poisson",
                   data = training_set)
    
    # Removing outlier
    training_set$res <- abs(training_set$sales - fitpois$fitted.values)
    training_set$res_prop <- abs(training_set$sales - fitpois$fitted.values)/fitpois$fitted.value
    
    topres <- quantile(training_set$res, .95)
    topresprop <- quantile(training_set$res_prop, .95)
    
    training_set %>% 
      filter(res < topres, res_prop < topresprop) %>% 
      select(-res, -res_prop) -> training_set
    
    # Checking discount level again after remove outliers
    if (dis_level > 1) {
      dis_level_second <- length(unique(training_set$dis_cat))
      dis_check_second <- unique(test_set$dis_cat) %in% unique(training_set$dis_cat)
      
    } else {
      dis_level_second <- 0
      dis_check_second <- T
    }
    
    if (dis_level_second > 1 & all(dis_check_second) == F) {
      
      fil_dis <- unique(test_set$dis_cat)[dis_check_second]
      test_set %>% 
        filter(dis_cat %in% fil_dis) -> test_set
      
    } else if (dis_level_second == 1) {
      
      training_set %>%
        ungroup() %>% 
        select(-dis_cat) -> training_set
      
      test_set %>% 
        ungroup() %>% 
        select(-dis_cat) -> test_set
      
    }
    
    # Fitting final poisson
    fitpois <- glm(sales ~ ., 
                   family = "poisson", 
                   data = training_set)
    
    # Coefficient checking
    age_coef <- fitpois$coefficients["age_week"]
    boost_coef <- fitpois$coefficients["boosting_flag1"]
    
    # Imputing boost_coef
    if (is.na(boost_coef)) {
      boost_coef <- 0
    }
    
    # Checking boost effect
    if (boost_level > 1) {
      training_set %>% 
        filter(boosting_flag == 1) -> last_boost
      last_boost <- max(last_boost$age_week)
    } else {
      last_boost <- NA
    }
    
    # Check boost coef
      if (boost_coef < 0) {
        boost_coef <- 0
        fitpois <- glm(sales ~ . -boosting_flag, 
                       family = "poisson", 
                       data = training_set)
      }
      
      # Validate
      test_set$pred <- predict(fitpois, newdata = test_set, type = "response")
      
      test_set %>% 
        group_by(age_week) %>% 
        summarise(actual = sum(sales), pred_sum = sum(pred)) -> result
      
      # Bias adjustment
      bias <- median(result$actual/result$pred_sum)
      
      result %>% 
        mutate(pred_sum = pred_sum * bias,
               res = actual - pred_sum) -> result
      
      # Measurement logging
      lamb_log <- data.frame(loop_index = i,
                             HS_brand = brand,
                             HS_model = model,
                             HS_subtype = sub_type,
                             Age_week = max(test_set$age_week),
                             n = nrow(training_set),
                             last_boost = last_boost,
                             age_co = as.numeric(age_coef),
                             boost_co = as.numeric(boost_coef),
                             RMSE = round(sqrt(mean(result$res^2)), digits = 2),
                             MAPE = round(mean(abs(result$res/result$pred_sum)*100), digits = 2),
                             bias = bias,
                             stringsAsFactors = F)
      
      # print(paste("=========", brand, model, "Prediction stage"))
      
      # Expand grid for prediction template
      if (dis_level_second != 0) {
        dis <- unique(training_set$dis_cat)
      } else {
        dis <- factor(1)
      }
      
      boost <- factor(0:1)
      week <- 0:104
      
      pred_tbl <- expand.grid(age_week = week,
                              dis_cat = dis,
                              boosting_flag = boost)
      
      # Prediction
      pred_tbl$pred <- predict(fitpois, newdata = pred_tbl, type = "response")
      
      # Cap maximum sales
      pred_tbl %>% 
        mutate(pred = pred*bias,
               pred = case_when(
                 pred > max(training_set$sales)*2 ~ round(max(training_set$sales)*2, digits = 2),
                 TRUE ~ round(pred, digits = 2))) -> pred_tbl
      
      # Fill missing discount
      dis_all <- 1:5
      pred_tbl %>% 
        mutate(dis_cat = as.numeric(dis_cat)) %>% 
        group_by(age_week, boosting_flag) %>% 
        complete(dis_cat = dis_all) %>% 
        fill(pred) -> pred_tbl
      
      pred_tbl %>% 
        mutate(trade_product_brand = brand,
               trade_product_model = model, 
               product_subtype = sub_type) %>% 
        select(trade_product_brand, trade_product_model, product_subtype,
               age_week, dis_cat, boosting_flag, pred) -> pred_tbl
      
      # Coerce to character
      pred_tbl$boosting_flag <- as.character(pred_tbl$boosting_flag)
      
      lambda <- bind_rows(lambda, pred_tbl)
      log_ML <- bind_rows(log_ML, lamb_log)
      
    }, error = function(e){cat("ERROR :",conditionMessage(e), "\n") })
  }
  
  ML_path <- paste0(log_path, "log_ML.csv")
  write_csv(log_ML, ML_path)
  # write_csv(log_skip, skip_path)
  return(lambda)
  
}