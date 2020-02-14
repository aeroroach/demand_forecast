library(tidyverse)
library(lubridate)

# Data reading ------------------------------------------------------------

dt_sales <- read_delim("calculate/input/INPUT_SALE_DATA_20200206_030000.dat", delim = "|")

dt_lambda <- read_delim("calculate/input/lambda_20200206_110117.csv", delim = "|")
dt_branch <- read_delim("calculate/input/branch_20200206_110122.csv", delim = "|")

dt_result <- read_csv("calculate/input/200211_report_check.csv")

# Discount mapping --------------------------------------------------------

source("calculate/02_data_reduction.R")

dt_sales <- data_reduc(dt_sales, dt_result)

# Result preparation --------------------------------------------------------

source("calculate/01_cal_prep.R")

dt_result <- prep_week(dt_result)

dt_mapp <- dis_map(dt_result, dt_sales)

# lambda mapping ----------------------------------------------------------

dt_mapp <- lambda_map(dt_mapp, dt_lambda)

dt_mapp <- branch_map(dt_mapp, dt_branch)

# calculate ---------------------------------------------------------------

dt_mapp %>% 
  mutate(cal_lambda = round((((frac_start/7)*pred_w_start) + ((frac_end/7)*pred_w_end))*dist, digits = 4)) -> dt_output

dt_output %>% 
  group_by(LOCATION_CODE, MAT_CODE, PRODUCT_SUBTYPE, TRADE_PRODUCT_BRAND, TRADE_PRODUCT_MODEL, COLOR, 
           PRODUCT_NAME, REQ_DATE, LUNCH_DATE, START_DATE, END_DATE) %>% 
  summarise(sum_lambda = sum(cal_lambda)) -> dt_output

# Map result back ---------------------------------------------------------

dt_output <- sales_map(dt_output, dt_result)
  
write_csv(dt_output, "calculate/output/sandbox_output.csv")
