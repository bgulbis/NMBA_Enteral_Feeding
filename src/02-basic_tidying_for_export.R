# basic tidying to send data

library(tidyverse)
library(stringr)
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
    tidy_data() %>%
    filter(location %in% c(
        "Cullen 2 E Medical Intensive Care Unit",
        "HVI Cardiovascular Intensive Care Unit",
        "Hermann 3 Shock Trauma Intensive Care Unit",
        "Jones 7 J Elective Neuro ICU",
        "Hermann 3 Transplant Surgical ICU",
        "HVI Cardiac Care Unit",
        "HVI Heart Failure ICU"))

measures <- read_data(dir_raw, "measures") %>%
    as.measures()

meds_sched <- read_data(dir_raw, "meds-sched-all") %>%
    as.meds_sched()

nmba <- c("cisatracurium", "rocuronium", "vecuronium", "vecuronium INJ")
tpn <- c("parenteral nutrition solution", "parenteral nutrition solution w/lytes")
pressor <- c("dopamine", "epinephrine", "norepinephrine", "phenylephrine", "vasopressin")

ref <- tibble(name = c(nmba, tpn, pressor), type = "med", group = "cont")

meds_cont <- read_data(dir_raw, "meds-cont-all") %>%
    as.meds_cont() %>%
    tidy_data(ref, meds_sched) %>%
    calc_runtime() %>%
    summarize_data() %>%
    filter(cum.dose > 0)

tof <- read_data(dir_raw, "icu-scores") %>%
    as.icu_assess() %>%
    filter(assessment == "train of four stimulation",
           !is.na(assess.result)) %>%
    select(-`Clinical Event Result Type`) %>%
    mutate(tof = str_extract(assess.result, "[0-4]{1}")) %>%
    dmap_at("tof", as.numeric)

dc <- patients <- read_data(dir_raw, "patients") %>%
    as.patients() %>%
    semi_join(include_pie, by = "pie.id")

vent <- read_data(dir_raw, "vent-times") %>%
    as.vent_times() %>%
    tidy_data(dc)

link <- read_data(dir_raw, "identifiers") %>%
    as.id() %>%
    semi_join(include_pie, by = "pie.id") %>%
    select(-person.id)

# export data

write_csv(meds_cont, "data/external/meds_continuous.csv")
write_csv(link, "data/external/linking_log.csv")
