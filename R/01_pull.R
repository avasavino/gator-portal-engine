# 01_pull.R — download raw data from CFBD into cache/
# Reads: CFBD API (key from .Renviron)   Writes: cache/*.parquet
# Safe to rerun: anything already in cache/ is read, not re-downloaded.

library(cfbfastR)   # college football data functions (cfbd_*)
library(dplyr)      # bind_rows(), filter(), etc.
source("R/loader.R")   # gives us get_cached()

years <- 2022:2026   # portal classes we care about (2022–2025 train, 2026 gets scored)

# --- Transfer portal entries, one file per year ---------------------------
# lapply() runs the same code once per year and returns a list of tables.
portal <- lapply(years, function(y) {
  get_cached(paste0("portal_", y), function() cfbd_recruiting_transfer_portal(year = y))
}) |>
  bind_rows()   # stacks the 5 yearly tables into one big table

# --- FBS team list, one per year -------------------------------------------
# Need 2021 too: a 2022 transfer's "before" season is 2021.
# cfbd_team_info() returns FBS teams only by default (only_fbs = TRUE).
fbs_teams <- lapply(2021:2026, function(y) {
  get_cached(paste0("fbs_teams_", y), function() cfbd_team_info(year = y)) |>
    mutate(year = y)   # tag each row with its year so we can tell them apart after stacking
}) |>
  bind_rows()
