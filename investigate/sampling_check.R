dt_mapp %>% 
  filter(MAT_CODE == "NEW0AP00112-WH01", 
         LOCATION_CODE == 1136, 
         REQ_DATE == ymd("2020-03-05")) -> dt_mapp

dt_lambda %>% 
  filter(trade_product_model == "IPHONE11128", boosting_flag == 0,
         trade_product_color == "WHITE", age_week %in% c(22,23)) -> test

# write_csv(test, "investigate/sampling_lambda.csv")
