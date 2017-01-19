# get patients

library(tidyverse)
library(lubridate)
library(edwr)

# run EDW query:
#   * Patients - by Medication
#       - cisatracurium, rocuronium, vecuronium, vecuronium INJ

patients <- read_data("data/raw", "patients") %>%
    as.patients()

excl_patients <- filter(patients, age < 18, discharge.datetime < ymd("2016-09-01"))

edw_pie <- concat_encounters(patients$pie.id)

# run EDW queries:
#   * Medications - Inpatient Continuous - All
#   * Medications - Inpatient Intermittent - All

nmba <- tibble(name = c("cisatracurium", "rocuronium", "vecuronium", "vecuronium INJ"),
               type = "med",
               group = "cont")

meds_sched <- read_data("data/raw", "meds_sched") %>%
    as.meds_sched()

meds_cont <- read_data("data/raw", "meds_cont") %>%
    as.meds_cont() %>%
    tidy_data(nmba, meds_sched) %>%
    calc_runtime() %>%
    summarize_data()

tpn <- tibble(name = c("parenteral nutrition solution", "parenteral nutrition solution w/ lytes"),
              type = "med",
              group = "cont")

tpn_cont <- read_data("data/raw", "meds_cont") %>%
    as.meds_cont() %>%
    tidy_data(tpn, meds_sched) %>%
    calc_runtime() %>%
    summarize_data()

nmba_24h <- meds_cont %>%
    filter(duration >= 24) %>%
    anti_join(excl_patients, by = "pie.id")
# join with tpn data and exclude overlap

# nmba_sum <- meds_cont %>%
#     group_by(pie.id) %>%
#     summarize(duration = sum(duration, na.rm = TRUE)) %>%
#     filter(duration >= 24)

edw_nmba_pie <- concat_encounters(unique(nmba_24h$pie.id))

# run EDW query: Enteral Feeding

feed <- read_data("data/raw", "feed") %>%
    as.events() %>%
    dmap_at("event.result", as.numeric)

overlap_feeds <- feed %>%
    inner_join(meds_cont, by = "pie.id") %>%
    filter(event.datetime >= start.datetime,
           event.datetime <= stop.datetime) %>%
    distinct(pie.id)

edw_include_pie <- concat_encounters(overlap_feeds$pie.id)

 # run EDW query: Identifiers - by PowerInsight Encounter Id

id <- read_data("data/raw", "identifiers") %>%
    as.id() %>%
    select(fin)

write_csv(id, "data/external/potential_fins.csv")
