HS_color <- function(full_dt, lambda, con_loop) {
  
  # Filtering latest month
  full_dt %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    filter(sale_date >= max(sale_date)-60) -> color_dist
  
  color_dist %>% 
    semi_join(con_loop, by = c("trade_product_brand", "trade_product_model")) -> color_dist
  
  # Sum up the proportion
  color_dist %>% 
    group_by(trade_product_brand, trade_product_model, trade_product_color) %>%
    summarise(sales = sum(sale_amount)) %>% 
    ungroup() %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    mutate(color_prop = sales/sum(sales), key = "a") %>% 
    select(-sales) -> color_dist
  
  # Full join combination
  lambda %>% 
    mutate(key = "a") %>% 
    full_join(color_dist, by = c("trade_product_brand", "trade_product_model", "key")) %>% 
    select(-key) -> lambda
  
  # Calculate color distribution
  lambda %>% 
    mutate(pred_col = round(pred * color_prop, digits = 2)) %>% 
    select(-pred,-color_prop) %>% 
    rename(pred = pred_col) -> lambda
  
  return(lambda)
}