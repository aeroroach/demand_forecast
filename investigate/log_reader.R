library(tidyverse)

lambda_tbl <- read_delim("output/lambda_20200317_144438.csv", delim = "|")

omit <- read_csv("log/omit_HS.csv")

pre <- read_csv("log/pre_Diag.csv")


# Log comparison ----------------------------------------------------------


log <- read_csv("log/log_ML_all.csv")

log_2m <- read_csv("log/log_ML_2m.csv")

log_3m <- read_csv("log/log_ML_3m.csv")

log %>% 
  select(HS_brand, HS_model, HS_subtype, RMSE, MAPE) %>% 
  left_join(select(log_2m, HS_brand, HS_model, HS_subtype, RMSE_2m = RMSE, MAPE_2m = MAPE),
            by = c("HS_brand", "HS_model", "HS_subtype")) %>% 
  left_join(select(log_3m, HS_brand, HS_model, HS_subtype, RMSE_3m = RMSE, MAPE_3m = MAPE),
            by = c("HS_brand", "HS_model", "HS_subtype")) -> log_compare

# Calculation -------------------------------------------------------------

mean(log_compare$RMSE, na.rm = T)
mean(log_compare$MAPE, na.rm = T)

mean(log_compare$RMSE_2m, na.rm = T)
mean(log_compare$MAPE_2m, na.rm = T)

mean(log_compare$RMSE_3m, na.rm = T)
mean(log_compare$MAPE_3m, na.rm = T)

# Filtering ---------------------------------------------------------------

fil_model <- c("A520-64CDMSL", "NOVA5T", "Y6SSL", "Y11CDMSL")

log_compare %>% 
  filter(HS_model %in% fil_model) -> log_sel

# plot --------------------------------------------------------------------

log_compare %>% 
  select(HS_brand:HS_subtype, RMSE, RMSE_2m, RMSE_3m) %>% 
  pivot_longer(RMSE:RMSE_3m, "rmse_group", values_drop_na = T) %>% 
  filter(value < 50) %>% 
  ggplot(aes(x = value)) + geom_histogram() + facet_grid(rows = vars(rmse_group))

log_compare %>% 
  select(HS_brand:HS_subtype, MAPE, MAPE_2m, MAPE_3m) %>% 
  pivot_longer(MAPE:MAPE_3m, "rmse_group", values_drop_na = T) %>% 
  filter(value < 100) %>%
  ggplot(aes(x = value)) + geom_histogram() + facet_grid(rows = vars(rmse_group))

