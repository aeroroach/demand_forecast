prep_week <- function(dt) {
  
  # Initial week calculation
  dt %>% 
    mutate(LUNCH_DATE = mdy(LUNCH_DATE), 
           START_DATE = mdy(START_DATE),
           END_DATE = mdy(END_DATE),
           REQ_DATE = mdy(REQ_DATE),
           w_start = ceiling((as.numeric(START_DATE - LUNCH_DATE) + 1)/7), 
           w_end = ceiling((as.numeric(END_DATE - LUNCH_DATE) + 1)/7), 
           frac_start_tmp = as.numeric(START_DATE - LUNCH_DATE)  %% 7,
           frac_start = 7 - frac_start_tmp, 
           frac_end = ((as.numeric(END_DATE - LUNCH_DATE) + 1) %% 7)) -> dt
  
  # Mutating condition
  dt %>% 
    mutate(frac_end = ifelse(frac_end == 0 & frac_start_tmp != 0, 7, frac_end)
    ) -> dt 
  
  return(dt)
  
}


dis_map <- function(dt, sales) {

  # Mapping discount
  sales %>%
    mutate(key = "a") -> sales

  dt %>%
    select(-FORECAST_SALE_AMT:-STOCK_END_DATE_AMT) %>%
    mutate(key = "a") %>% 
    full_join(dt_sales, by = c("TRADE_PRODUCT_BRAND"="trade_product_brand",
                               "TRADE_PRODUCT_MODEL"="trade_product_model",
                               "PRODUCT_SUBTYPE"="product_subtype",
                               "COLOR"="trade_product_color",
                               "REQ_DATE"="sale_date")) %>% 
    select(-key) %>% 
    filter(!is.na(dis_cat)) -> dt
                
    return(dt)

}

lambda_map <- function(dt, dt_lambda) {

  dt_lambda %>% 
    filter(boosting_flag  == 0) %>% 
    select(-boosting_flag) -> dt_lambda
  
  dt %>%
    left_join(dt_lambda, by = c("TRADE_PRODUCT_BRAND"="trade_product_brand",
                                "TRADE_PRODUCT_MODEL"="trade_product_model",
                                "PRODUCT_SUBTYPE"="product_subtype",
                                "w_start"="age_week",
                                "dis_cat", 
                                "COLOR"="trade_product_color")) %>% 
    left_join(dt_lambda, by = c("TRADE_PRODUCT_BRAND"="trade_product_brand",
                                "TRADE_PRODUCT_MODEL"="trade_product_model",
                                "PRODUCT_SUBTYPE"="product_subtype",
                                "w_end"="age_week",
                                "dis_cat", 
                                "COLOR"="trade_product_color"), 
              suffix = c("","_w_end")) %>% 
    rename(pred_w_start = pred) -> dt
  
  return(dt)
  
}

branch_map <- function(dt, dt_branch) {
  
  dt %>% 
    left_join(dt_branch, by = c("TRADE_PRODUCT_BRAND"="trade_product_brand", 
                                "TRADE_PRODUCT_MODEL"="trade_product_model",
                                "PRODUCT_SUBTYPE"="product_subtype",
                                "LOCATION_CODE"="trade_location_code")) -> dt
  
  return(dt)
  
}

sales_map <- function(dt, dt_result) {
  
  dt_result %>% 
    select(LOCATION_CODE:END_DATE, FORECAST_SALE_AMT, SALE_AMT, STOCK_ON_HAND_AMT) -> dt_result
  
  dt %>% 
    left_join(dt_result, by = c("LOCATION_CODE", "MAT_CODE", "PRODUCT_SUBTYPE", "TRADE_PRODUCT_BRAND", "TRADE_PRODUCT_MODEL", 
                                "COLOR", "PRODUCT_NAME", "REQ_DATE", "LUNCH_DATE", "START_DATE", "END_DATE")) %>% 
    mutate(SALE_AMT = ifelse(is.na(SALE_AMT), 0, SALE_AMT), 
           sum_lambda = ifelse(is.na(sum_lambda), 0, sum_lambda)) -> dt
  
  return(dt)
  
}