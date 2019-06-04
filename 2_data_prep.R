data_prep <- function(full_dt, log_path) {

  
# Categorize discount campaign --------------------------------------------
  
  print(paste("========= Data manipulating"))
  full_dt %>% 
    mutate(propdis = handset_discount_amt/retail_price*100,
           dis_cat = cut(propdis, breaks = c(1,20,40,60,Inf), right = F,
                         labels = c("02:dis < 20%", 
                                    "03:20% <= dis < 40%", 
                                    "04:40% <= dis < 60%",
                                    "05:dis >= 60%")),
           dis_cat = ifelse(is.na(dis_cat),"01:No Discount",as.character(dis_cat))) -> full_dt 
  
# Boosting flag -----------------------------------------------------------

  # Initiate price master
  full_dt %>% 
    select(trade_product_brand, trade_product_model ,age_week, retail_price) %>% 
    distinct() %>% 
    group_by(trade_product_brand, trade_product_model, age_week) %>% 
    filter(retail_price == max(retail_price)) -> price_master
  
  # Joining previous price back
  full_dt %>% 
    mutate(prev_4_week = age_week - 4) %>% 
    left_join(rename(price_master, prev_price = retail_price),
              by = c("trade_product_brand", "trade_product_model", "prev_4_week"="age_week")) %>% 
    mutate(price_diff = (prev_price - retail_price)/retail_price,
           price_diff = ifelse(is.na(price_diff),0,price_diff),
           price_drop_flag = ifelse(price_diff >= 0.1, 1, 0)) -> full_dt
  
  # Initiate min week
  full_dt %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    mutate(min_week = min(age_week)) %>% 
    filter(min_week >= 0) %>% 
    filter(age_week > min_week +4) %>% 
    mutate(min_week = min(age_week)) %>% 
    ungroup() %>% 
    mutate(launch_flag = ifelse(age_week <= min_week + 4, 1, 0),
           boosting_flag = ifelse(price_drop_flag == 1 | launch_flag == 1,1,0)) -> full_dt

# Aggregate data for fitting ----------------------------------------------

  print(paste("========= Final aggregation for model fitting"))
  full_dt %>% 
    group_by(trade_product_brand,trade_product_model, age_week, dis_cat, boosting_flag) %>%
    summarise(sales = sum(sale_amount)) %>% 
    ungroup() -> agg_dt


# Factorize features ------------------------------------------------------

  agg_dt %>% 
    mutate(boosting_flag = factor(boosting_flag,
                                  levels = c(0,1)),
           dis_cat = factor(dis_cat,
                            levels = c("01:No Discount",
                                       "02:dis < 20%",
                                       "03:20% <= dis < 40%",
                                       "04:40% <= dis < 60%",
                                       "05:dis >= 60%"),
                            labels = c(1,2,3,4,5),
                            ordered = F)) -> agg_dt
  
# Filtering criteria ------------------------------------------------------

  # Initiate low obs table
  agg_dt %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    summarise(max_w = max(age_week),
              min_w = min(age_week),
              range = max_w - min_w,
              n = n()) %>% 
    filter(range < 8 | n < 10 | max_w > 208) -> agg_exclude
  
  omit_path = paste0(log_path, "omit_HS.csv")
  write_csv(agg_exclude, omit_path)
  
  print(paste("========= Omitting", nrow(agg_exclude), "Handsets due to very low sales volume"))
  
  # Anti-join
  agg_dt %>% 
    anti_join(agg_exclude, by = c("trade_product_brand", "trade_product_model")) -> agg_dt
  
  return(agg_dt)
}