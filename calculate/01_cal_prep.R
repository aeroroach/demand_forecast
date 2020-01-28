library(tidyverse)
library(lubridate)

dt <- read_csv(file = "calculate/input/191226_report_check.csv")

dt %>% distinct(START_DATE, END_DATE) -> fore_date

dt %>% 
  mutate(LUNCH_DATE = dmy(LUNCH_DATE), 
         START_DATE = dmy(START_DATE), 
         END_DATE = dmy(END_DATE), 
         age_d_st = as.numeric(START_DATE - LUNCH_DATE),
         age_w_st = age_d_st %/% 7, 
         age_w_st_frac = age_d_st %% 7, 
         age_d_en = as.numeric(END_DATE - LUNCH_DATE), 
         age_w_en = age_d_en %/% 7,
         age_w_en_frac = age_d_en %% 7) %>% 
  glimpse()
  
