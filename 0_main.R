# Library loading ---------------------------------------------------------

print(paste(Sys.time(), ": Starting forecast"))

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)

# Working path ------------------------------------------------------------

# Checking working environment
if(Sys.info()["sysname"] == "Windows") {
  
  script_path <- "D:/R_project/HS_Forecast/"
  file_path <- "D:/R_project/HS_Forecast/input/"
  con_name <- "latest_control.dat"
  dt_name <- "latest_TDM_HS.dat"
  map_name <- "model_mapping.csv"
  log_path <- "D:/R_project/HS_Forecast/log/"
  out_path <- "D:/R_project/HS_Forecast/output/"
  
} else {
  
  script_path <- "/home/tdmdf/HS_forecast/script/"
  file_path <- "/home/tdmdf/HS_forecast/input/"
  con_name <- "latest_control.dat"
  dt_name <- "latest_TDM_HS.dat"
  map_name <- "model_mapping.csv"
  log_path <- "/home/tdmdf/HS_forecast/log/"
  out_path <- "/home/tdmdf/HS_forecast/output/"
  
}

# Data reading ------------------------------------------------------------

print(paste("====== Data cleansing in progress"))

fn_path <- paste0(script_path, "1_data_cleansing.R")

source(fn_path)

full_dt <- data_clean(file_path, con_name, dt_name)

# Data preparation --------------------------------------------------------

print(paste("====== Data Preperation in progress"))

fn_path <- paste0(script_path, "2_data_prep.R")

source(fn_path)

trade_agg <- data_prep(full_dt, log_path)

# Generating loop control -------------------------------------------------

trade_agg %>% 
  distinct(trade_product_brand, trade_product_model) -> con_loop

con_loop$index <- 1:nrow(con_loop)

# Pre-Diagnostics ---------------------------------------------------------

print(paste("====== Pre Diagnostics in progress"))

fn_path <- paste0(script_path, "3_pre_diag.R")

source(fn_path)

pre_diag(trade_agg, con_loop, log_path)

# Splitting data ----------------------------------------------------------

print(paste("====== Data splitting"))

fn_path <- paste0(script_path, "4_splitting.R")

source(fn_path)

trade_agg <- trade_split(trade_agg)


# Model Training & Prediction ---------------------------------------------


print(paste("====== Model training & prediction"))

fn_path <- paste0(script_path, "5_ML.R")

source(fn_path)

lambda <- HS_forecast(trade_agg, con_loop, log_path)


# Color distribution ------------------------------------------------------

# Revising con loop base on lambda
lambda %>% 
  ungroup() %>% 
  distinct(trade_product_brand, trade_product_model) -> con_loop

print(paste("====== Color mapping"))

fn_path <- paste0(script_path, "6_color.R")

source(fn_path)

lambda <- HS_color(full_dt, lambda, con_loop)

# Branch distribution -----------------------------------------------------

print(paste("====== Branch distribution"))

fn_path <- paste0(script_path, "7_branch.R")

source(fn_path)

branch <- HS_branch(full_dt)

# Model Mapping -----------------------------------------------------------


print(paste("====== Model Mapping"))

fn_path <- paste0(script_path, "8_mapping.R")

source(fn_path)

result_mapped <- HS_map(file_path ,map_name , lambda, branch, full_dt, con_name)

lambda <- result_mapped$lambda
branch <- result_mapped$branch

# Writing File ------------------------------------------------------------

lambda_name <- paste0("lambda_", format(Sys.time(), format = "%Y%m%d_%H%M%S"), ".csv")
write_delim(lambda, paste0(out_path, lambda_name), delim = "|")
print(paste("====== Finishing writing lambda file"))

branch_name <- paste0("branch_", format(Sys.time(), format = "%Y%m%d_%H%M%S"), ".csv")
write_delim(branch, paste0(out_path, branch_name), delim = "|")
print(paste("====== Finishing writing branch file"))

print(paste(Sys.time(), ": Forecast completed"))

# End of process ----------------------------------------------------------
