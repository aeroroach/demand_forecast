
# Model Mapping -----------------------------------------------------------

model_mapping <- sort(list.files("input/raw/", pattern = "model_mapping"), decreasing = T)
file.copy(from = paste0("input/raw/",model_mapping[1]), 
          to = "input/model_mapping.dat", overwrite = T)

# Control -----------------------------------------------------------------

latest_control <- sort(list.files("input/raw/", pattern = "INPUT_LUNCH_DATE"), decreasing = T)
file.copy(from = paste0("input/raw/",latest_control[1]), 
          to = "input/latest_control.dat", overwrite = T)

# Latest Sales ------------------------------------------------------------

latest_sales <- sort(list.files("input/raw/", pattern = "INPUT_SALE_DATA"), decreasing = T)
file.copy(from = paste0("input/raw/",latest_sales[1]), 
          to = "input/latest_TDM_HS.dat", overwrite = T)

# Print latest files ------------------------------------------------------

print(latest_control[1])
print(latest_sales[1])
print(model_mapping[1])
