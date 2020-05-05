library(lubridate)
library(tidyverse)

dt <- read_csv("shiny/input/sandbox_output.csv")

# Mapping age calculation
dt %>% 
  filter(REQ_DATE >= as.Date("2020-03-01")) %>% 
  mutate(w_start = ceiling((as.numeric(START_DATE - LUNCH_DATE) + 1)/7), 
         w_end = ceiling((as.numeric(END_DATE - LUNCH_DATE) + 1)/7), 
         frac_start_tmp = as.numeric(START_DATE - LUNCH_DATE)  %% 7,
         frac_start = 7 - frac_start_tmp, 
         frac_end = ((as.numeric(END_DATE - LUNCH_DATE) + 1) %% 7)) -> dt

# Filtering HS age
dt %>% 
  filter(w_start > 8) -> dt

# Calculate 0.95 poisson
dt %>% 
  mutate(pois_95 = qpois(0.95, sum_lambda)) -> dt

# Selected column and export
dt %>% 
  select(LOCATION_CODE:END_DATE, w_start:frac_end,
         sum_lambda, pois_95, FORECAST_SALE_AMT) %>% 
  mutate(diff_forecast = abs(pois_95 - FORECAST_SALE_AMT)) -> comparison

comparison %>% 
  arrange(desc(diff_forecast)) %>% 
  top_n(1000) -> comparison

write_csv(comparison, "investigate/cal_comparison.csv")
