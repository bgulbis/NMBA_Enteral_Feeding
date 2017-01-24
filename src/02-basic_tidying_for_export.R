# basic tidying to send data

library(tidyverse)
library(lubridate)
library(edwr)

dir_raw <- "data/raw"
include_pie <- read_rds("data/tidy/include_pie.Rds")

demographics <- read_data(dir_raw, "demographics") %>%
    as.demographics() %>%
    select(pie.id:race, length.stay)

enteral_feeds <- read_data(dir_raw, "feed") %>%
    as.events() %>%
    semi_join(include_pie, by = "pie.id") %>%
    dmap_at("event.result", as.numeric)

labs <- read_data(dir_raw, "labs") %>%
    as.labs() %>%
    tidy_data() %>%
    filter(lab %in% c("bun", "creatinine lvl", "egfr", "glucose lvl",
                      "osmolality", "sodium lvl"))

locations <- read_data(dir_raw, "locations") %>%
    as.locations() %>%
    tidy_data()

measures <- read_data(dir_raw, "measures") %>%
    as.measures()

meds_sched <- read_data(dir_raw, "meds-sched-all") %>%
    as.meds_sched()

nmba <- c("cisatracurium", "rocuronium", "vecuronium", "vecuronium INJ")
tpn <- c("parenteral nutrition solution", "parenteral nutrition solution w/ lytes")
pressor <- c("dopamine", "epinephrine", "norepinephrine", "phenylephrine", "vasopressin")

ref <- tibble(name = c(nmba, tpn, pressor), type = "med", group = "cont")

meds_cont <- read_data(dir_raw, "meds-cont-all") %>%
    as.meds_cont() %>%
    tidy_data(ref, meds_sched)

tof <- read_data(dir_raw, "icu-scores") %>%
    as.icu_assess()
