lambda_tbl <- read_delim("/data01/pitchaym/HS_forecast/output/lambda_20190306_185339.csv", delim = "|")

omit <- read_csv("/data01/pitchaym/HS_forecast/log/omit_HS.csv")

short <- read_csv("/data01/pitchaym/HS_forecast/production/log_short.csv")

log <- read_csv("/data01/pitchaym/HS_forecast/log/log_ML.csv")

pre <- read_csv("/data01/pitchaym/HS_forecast/production/pre_Diag.csv")

hist(lambda_tbl$pred)

