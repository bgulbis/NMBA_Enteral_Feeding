library(tidyverse)
library(readxl)
library(broom)

nm <- c("goal", "pressor_avg", "osmolality", "motility_agent")

df <- read_excel("data/external/regression_data.xls", col_names = nm, skip = 1) %>%
    dmap_at(c("goal", "motility_agent"), ~ .x == 1)

mod <- glm(goal ~ pressor_avg + osmolality + motility_agent, df, family = "binomial")
summary(mod)

glance(mod)
tidy(mod)
