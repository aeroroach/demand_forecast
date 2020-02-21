data_reduc <- function(dt, dt_result) {
  
  # Distinct and encoding the discount
  dt %>% 
    distinct(sale_date, trade_product_brand, trade_product_model, trade_product_color, 
             product_subtype, retail_price, handset_discount_amt) %>% 
    mutate(propdis = handset_discount_amt/retail_price*100,
           dis_cat = cut(propdis, breaks = c(1,20,40,60,Inf), right = F,
                         labels = c("02:dis < 20%", 
                                    "03:20% <= dis < 40%", 
                                    "04:40% <= dis < 60%",
                                    "05:dis >= 60%")),
           dis_cat = ifelse(is.na(dis_cat),"01:No Discount",as.character(dis_cat))) %>% 
    mutate(dis_cat = factor(dis_cat,
                            levels = c("01:No Discount",
                                       "02:dis < 20%",
                                       "03:20% <= dis < 40%",
                                       "04:40% <= dis < 60%",
                                       "05:dis >= 60%"),
                            labels = c(1,2,3,4,5),
                            ordered = F), 
           dis_cat = as.numeric(dis_cat)) %>% 
    distinct(sale_date, trade_product_brand, trade_product_model, trade_product_color, 
             product_subtype, dis_cat) -> dt
  
  # Filtering only available items
  dt_result %>% 
    mutate(REQ_DATE = mdy(REQ_DATE)) -> dt_result
  
  dt %>% 
    semi_join(dt_result, by = c("trade_product_brand"="TRADE_PRODUCT_BRAND",
                                "trade_product_model"="TRADE_PRODUCT_MODEL",
                                "product_subtype"="PRODUCT_SUBTYPE",
                                "trade_product_color"="COLOR",
                                "sale_date"="REQ_DATE")) -> dt
  
  return(dt)
  
}