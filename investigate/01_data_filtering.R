library(tidyverse)
library(lubridate)

# Prerequisite ------------------------------------------------------------

source("1_data_cleansing.R")
source("2_data_prep.R")

script_path <- "D:/R_project/Demand_Forecast/"
file_path <- "D:/R_project/Demand_Forecast/input/"
con_name <- "latest_control.dat"
dt_name <- "latest_TDM_HS.dat"
map_name <- "model_mapping.dat"
log_path <- "D:/R_project/Demand_Forecast/log/"
out_path <- "D:/R_project/Demand_Forecast/output/"

# Data Reading ------------------------------------------------------------


full_dt <- data_clean(file_path, con_name, dt_name)

fil_model <- c("A520-64CDMSL", "NOVA5T", "Y6SSL", "Y11CDMSL")

full_dt %>% 
  filter(trade_product_model %in% fil_model) -> full_dt

trade_agg <- data_prep(full_dt, log_path)

lambda <- read_delim("output/lambda_20200318_143500.csv", delim = "|")

lambda %>% 
  filter(trade_product_model %in% fil_model) %>% 
  group_by(trade_product_brand, trade_product_model, product_subtype, age_week,
           dis_cat, boosting_flag) %>% 
  summarise(sum_pred = sum(pred)) %>% 
  ungroup() %>% 
  mutate(dis_cat = factor(dis_cat), 
         boosting_flag = factor(boosting_flag)) -> lambda

# Joining data ------------------------------------------------------------

trade_agg %>% 
  left_join(lambda,by = c("trade_product_brand", "trade_product_model", "product_subtype", 
                          "age_week", "dis_cat", "boosting_flag")) %>% 
  filter(boosting_flag == 0) -> trade_agg


# Aggregate ---------------------------------------------------------------

trade_agg %>% 
  group_by(trade_product_brand, trade_product_model, product_subtype, 
           age_week) %>% 
  summarise(sales_week = sum(sales)) -> trade_sum

trade_agg %>% 
  group_by(trade_product_brand, trade_product_model, product_subtype, 
           age_week) %>% 
  summarise(pred_week = sum(sum_pred)) -> pred_sum

trade_sum %>% 
  left_join(pred_sum,by = c("trade_product_brand", "trade_product_model", "product_subtype", 
                          "age_week")) %>% 
  arrange(trade_product_brand, trade_product_model, product_subtype, age_week) -> trade_sum_compare

