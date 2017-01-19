# get patients

library(tidyverse)
library(readxl)
library(lubridate)
library(edwr)

# run EDW query:
#   * Patients - by Medication
#       - cisatracurium, rocuronium, vecuronium, vecuronium INJ

patients <- read_data("data/raw", "patients") %>%
    as.patients() %>%
    filter(age >= 18,
           discharge.datetime < ymd("2016-09-01"))

edw_pie <- concat_encounters(patients$pie.id)

# run EDW queries:
#   * Medications - Inpatient Continuous - Prompt
#       - cisatracurium, rocuronium, vecuronium, vecuronium INJ
#   * Medications - Inpatient Intermittent - Prompt
#       - cisatracurium, rocuronium, vecuronium, vecuronium INJ

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

nmba_24h <- meds_cont %>%
    filter(duration >= 24) %>%
    distinct(pie.id)

edw_nmba_pie <- concat_encounters(nmba_24h$pie.id)

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

# get status of fins that have already been screened
include_sample <- read_excel("data/external/included_fins_sample.xlsx") %>%
    dmap(as.character) %>%
    rename(fin = include) %>%
    mutate(include = TRUE)

pts_sample <- read_excel("data/external/potential_fins_sample.xlsx") %>%
    dmap(as.character) %>%
    left_join(include_sample, by = "fin") %>%
    dmap_at("include", ~ coalesce(.x, FALSE))

id <- read_data("data/raw", "identifiers") %>%
    as.id() %>%
    left_join(pts_sample, by = "fin")

pts_screen <- select(id, fin, include)

write_csv(pts_screen, "data/external/potential_fins_all.csv")
