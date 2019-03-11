trade_split <- function(trade_agg,
                        train_prop = 0.75) {
  
  # Initiate training index
  trade_agg %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    mutate(range_week = round((max(age_week) - min(age_week))*train_prop, digits = 0),
           index = min(age_week) + range_week) -> trade_agg
  
  # Data Splitting
  trade_agg %>% 
    filter(age_week <= index) -> training_set
  
  trade_agg %>% 
    filter(age_week > index) -> test_set
  
  # Combining in list
  trade_agg <- list(train = training_set,
                    test = test_set)
  
  return(trade_agg)
}