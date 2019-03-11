HS_map <- function(file_path ,map_name , lambda, branch, full_dt, con_name) {
  
  # Initiate mapping path
  map_path <- paste0(file_path, map_name)
  
  # Reading data
  new_hs <- read_csv(map_path)
  new_hs %>% 
    rename(new_brand = trade_product_brand) %>% 
    rename(new_model = trade_product_model) -> new_hs
  
  # Making sure for the new model
  new_hs %>% 
    anti_join(lambda, by = c("new_brand"="trade_product_brand", 
                             "new_model"="trade_product_model")) -> new_hs
  
  # Select existing model in lambda
  branch %>% 
    semi_join(lambda, by = c("trade_product_brand", "trade_product_model")) -> branch
  
# Lambda Mapping ----------------------------------------------------------
  
  # Selecting available model mapping
  lambda %>% 
    semi_join(new_hs, by = c("trade_product_brand"="map_brand", 
                             "trade_product_model"="map_model")) -> lambda_map
  
  # Mapping model
  lambda_map %>%
    left_join(new_hs, by = c("trade_product_brand"="map_brand", 
                             "trade_product_model"="map_model")) %>%
    ungroup() %>% 
    select(-trade_product_brand, -trade_product_model) %>% 
    select(trade_product_brand = new_brand, trade_product_model = new_model, 
           age_week, dis_cat, boosting_flag, trade_product_color, pred) -> lambda_map
  
  # Ignoring color aggregate
  lambda_map %>% 
    group_by(trade_product_brand, trade_product_model, age_week, dis_cat, boosting_flag) %>% 
    summarise(pred = sum(pred)) -> lambda_map
  
  # Loading new model color
  control_path <- paste0(file_path, con_name)
  new_col <- read_delim(control_path, delim = "|")
  
  new_col %>% 
    semi_join(new_hs, by = c("trade_product_brand"="new_brand",
                             "trade_product_model"="new_model")) %>% 
    distinct(trade_product_brand, trade_product_model, trade_product_color) -> new_col
  
  # Counting new color
  new_col %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    summarise(n_col = n()) -> count_col
  
  # Mapping back counting to new_col
  new_col %>% 
    left_join(count_col, by = c("trade_product_brand", "trade_product_model")) %>% 
    mutate(key = "a") -> new_col
  
  # Cross join the color combination
  lambda_map %>% 
    mutate(key = "a") %>% 
    full_join(new_col, by = c("trade_product_brand", "trade_product_model", "key")) %>% 
    select(-key) -> lambda_map
  
  # Calculate average lambda
  lambda_map %>% 
    mutate(pred = round(pred/n_col, digits = 2)) %>% 
    select(trade_product_brand:boosting_flag, trade_product_color, pred) %>% 
    filter(!is.na(pred)) -> lambda_map
  
  # Binding row
  lambda <- bind_rows(lambda, lambda_map)

# Branch Mapping ----------------------------------------------------------

  # Selecting available data in full dt and generating new dist
  full_dt %>% 
    semi_join(new_hs, by = c("trade_product_brand"="map_brand", 
                             "trade_product_model"="map_model")) %>% 
    group_by(trade_product_brand, trade_product_model, trade_location_code) %>% 
    filter(sale_date <= min(sale_date) + 90) %>%  
    summarise(sales = sum(sale_amount)) %>% 
    ungroup() %>% 
    group_by(trade_product_brand, trade_product_model) %>% 
    mutate(dist = sales/sum(sales)) %>% 
    select(-sales) -> branch_map
  
  # Mapping branch
  branch_map %>%
    left_join(new_hs, by = c("trade_product_brand"="map_brand", 
                             "trade_product_model"="map_model")) %>%
    ungroup() %>% 
    select(-trade_product_brand, -trade_product_model) %>% 
    select(trade_product_brand = new_brand, trade_product_model = new_model, 
           trade_location_code, dist) -> branch_map
  
  # Binding row
  branch <- bind_rows(branch, branch_map)
  
# Creat list --------------------------------------------------------------

  result_mapped <- list(lambda = lambda, 
                      branch = branch)
  
  return(result_mapped)
}