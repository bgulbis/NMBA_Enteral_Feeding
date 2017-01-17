# get patients

library(tidyverse)
library(edwr)

# run EDW query:
#   * Patients - by Medication
#       - atracurium, cisatracurium, pancruonium, rocuronium, vecuronium, vecuronium INJ

patients <- read_data("data/raw", "patients") %>%
    as.patients()

edw_pie <- concat_encounters(patients$pie.id)

# run EDW queries:
#   * Medications - Inpatient Continuous - Prompt
#       - atracurium, cisatracurium, pancruonium, rocuronium, vecuronium, vecuronium INJ
#   * Medications - Inpatient Intermittent - Prompt
#       - atracurium, cisatracurium, pancruonium, rocuronium, vecuronium, vecuronium INJ

nmba <- tibble(name = c("atracurium", "cisatracurium", "pancruonium", "rocuronium", "vecuronium", "vecuronium INJ"),
               type = "med",
               group = "cont")

meds_sched <- read_data("data/raw", "meds_sched") %>%
    as.meds_sched()

meds_cont <- read_data("data/raw", "meds_cont") %>%
    as.meds_cont() %>%
    tidy_data(nmba, meds_sched) %>%
    calc_runtime() %>%
    summarize_data()

nmba_24h <- filter(meds_cont, duration >= 24)
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

