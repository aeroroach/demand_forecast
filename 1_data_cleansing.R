data_clean <- function(file_path, con_name, dt_name) {
  
  # Initialize working path
  dt_path <- paste0(file_path, dt_name)
  control_path <- paste0(file_path, con_name)
  
  # Filtering NA and free campaign
  full_dt <- read_delim(dt_path, delim = "|")
  freecam <- c("DEVICE MIGRATION 3", "CRMCASHBACKONLINE", "JAK HAI", "AIS JUD AND JAK HAI",
               "H/S FREEVER")
  
  full_dt %>% 
    filter(!(trade_project_type %in% freecam),
           !is.na(retail_price)) -> full_dt
  
  # Select only active HS
  con <- read_delim(control_path, delim = "|")
  
  con %>%
    select(trade_product_brand, trade_product_model, launch_date) %>% 
    distinct() %>% 
    arrange(trade_product_brand, trade_product_model, launch_date) %>% 
    group_by(trade_product_brand, trade_product_model) %>%
    top_n(-1) -> model_con
  
  # Filtering full dt base on control path
  full_dt %>% 
    semi_join(model_con, by = c("trade_product_brand", "trade_product_model")) -> full_dt
  
  # Joining launch date
  full_dt %>% 
    left_join(select(model_con, trade_product_brand, trade_product_model, launch_date), 
              by = c("trade_product_brand", "trade_product_model")) %>%
    mutate(age_week = ceiling(as.numeric(sale_date - ymd(launch_date))/7)) -> full_dt
  
  return(full_dt)
  
}
