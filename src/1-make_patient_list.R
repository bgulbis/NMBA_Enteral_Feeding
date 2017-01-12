# get patients

library(tidyverse)
library(edwr)

# run EDW query: Patients - by Medication

patients <- read_data("data/raw", "patients") %>%
    as.patients()

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
    tidy_data(nmba, meds_sched)

edw_nmba_pie <- concat_encounters(meds_cont$pie.id)
