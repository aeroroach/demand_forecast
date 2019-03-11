HS_branch <- function(full_dt) {
  
  # Filtering latest month
  full_dt %>% 
    group_by(trade_product_brand, trade_product_model, trade_location_code) %>% 
    filter(sale_date >= max(sale_date)-30) -> branch_dist
  
  # Summarise data
  branch_dist %>% 
    group_by(trade_product_brand, trade_product_model, trade_location_code) %>%
    summarise(sales = sum(sale_amount)) %>% 
    ungroup() %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    mutate(dist = sales/sum(sales)) %>% 
    select(-sales) -> branch_dist
  
}