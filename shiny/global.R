# Define global variables for shiny app

library(shiny)
library(shinyWidgets)
library(shinydashboard)
library(lubridate)
library(tidyverse)
library(DT)

menu_fil <- read_csv("filter_list.csv")
dt <- read_csv("input/sandbox_output.csv")


# Remove the obsolete product ---------------------------------------------

dt %>% 
  filter(STOCK_ON_HAND_AMT > 0, SALE_AMT > 0) %>% 
  mutate(SALE_AMT = ifelse(is.na(SALE_AMT),0,SALE_AMT), 
         LOCATION_CODE = as.character(LOCATION_CODE))  -> dt


# Calculate measure -------------------------------------------------------

dt %>%
  mutate(prop_error = round((FORECAST_SALE_AMT - SALE_AMT)/FORECAST_SALE_AMT*100, digits = 3),
         SKU_error = FORECAST_SALE_AMT - SALE_AMT) %>%
  select(LOCATION_CODE, PRODUCT_NAME, COLOR, FORECAST_SALE_AMT, SALE_AMT,
         prop_error, SKU_error,
         REQ_DATE, START_DATE, END_DATE) -> dt_bau