# loader.R — "never download twice"
# get_cached() saves every download to cache/ as a parquet file.
# The first call downloads; every later call reads the saved file instead
# (fast, works offline, and doesn't use up CFBD API calls).

library(arrow)   # read_parquet() / write_parquet(): fast, small table files

get_cached <- function(name, fetch) {
  # name  = short label for the file, e.g. "portal_2024"
  # fetch = a function that does the actual download, e.g. function() cfbd_team_info(year = 2024)
  path <- file.path("cache", paste0(name, ".parquet"))   # builds "cache/portal_2024.parquet"

  # Step 1: already downloaded? Read the saved copy and stop here.
  if (file.exists(path)) {
    return(read_parquet(path))
  }

  # Step 2: not saved yet, so download it now.
  message("Downloading ", name, " ...")   # prints a note so you know it's hitting the internet
  data <- fetch()

  # Step 3: save it for next time, then hand it back.
  dir.create("cache", showWarnings = FALSE)   # makes cache/ if it's missing (e.g. fresh clone)
  write_parquet(data, path)
  data
}
