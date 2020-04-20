library(tidyverse)
library(lubridate)

# Data reading ------------------------------------------------------------

dt_sales <- read_delim("input/latest_TDM_HS.dat", delim = "|")

# Getting latest lambda
last_lambda <- sort(list.files("output/", pattern = "lambda"), decreasing = T)[1]
dt_lambda <- read_delim(paste0("output/",last_lambda ), delim = "|")

# Getting latest branch
last_branch <- sort(list.files("output/", pattern = "branch"), decreasing = T)[1]
dt_branch <- read_delim(paste0("output/",last_branch ), delim = "|")

# Run the merge file function once
# source("calculate/03_merge_file.R")
dt_result <- read_csv("calculate/input/latest3m_report.csv")

# Discount mapping --------------------------------------------------------

source("calculate/02_data_reduction.R")

dt_sales <- data_reduc(dt_sales, dt_result)

print("========= Discount rate mapping completed")

# Result preparation --------------------------------------------------------

source("calculate/01_cal_prep.R")

dt_result <- prep_week(dt_result)

dt_mapp <- dis_map(dt_result, dt_sales)

print("========= Age week preparation mapping completed")

# lambda mapping ----------------------------------------------------------

dt_mapp <- lambda_map(dt_mapp, dt_lambda)

dt_mapp <- branch_map(dt_mapp, dt_branch)

print("========= Lambda mapping completed")

# calculate ---------------------------------------------------------------

dt_mapp %>% 
  mutate(cal_lambda = round((((frac_start/7)*pred_w_start) + ((frac_end/7)*pred_w_end))*dist, digits = 4)) -> dt_output

dt_output %>% 
  group_by(LOCATION_CODE, MAT_CODE, PRODUCT_SUBTYPE, TRADE_PRODUCT_BRAND, TRADE_PRODUCT_MODEL, COLOR, 
           PRODUCT_NAME, REQ_DATE, LUNCH_DATE, START_DATE, END_DATE) %>% 
  summarise(sum_lambda = sum(cal_lambda)) -> dt_output

# Map result back ---------------------------------------------------------

dt_output <- sales_map(dt_output, dt_result)
  
write_csv(dt_output, "shiny/input/sandbox_output.csv")

print("========= Output file has been written")
