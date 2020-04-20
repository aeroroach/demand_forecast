library(tidyverse)

ls_file <- sort(list.files("calculate/input/raw/"), decreasing = T)[1:3]

ls_file <- paste0("calculate/input/raw/", ls_file)

dt <- map_dfr(ls_file, read_csv)

write_csv(dt, "calculate/input/latest3m_report.csv")
