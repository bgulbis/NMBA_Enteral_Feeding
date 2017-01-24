# basic tidying to send data

library(tidyverse)
library(lubridate)
library(edwr)

dir_raw <- "data/raw"
include_pie <- read_rds("data/tidy/include_pie.Rds")

demographics <- read_data(dir_raw, "demographics") %>%
    as.demographics()

