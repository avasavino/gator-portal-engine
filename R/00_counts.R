library(tidyr)
source("R/01_pull.R")

skill <- portal |>
# keeps rows with these positions only %in% = is one of 
  filter(position %in% c("RB", "WR", "TE", "QB")) |>
  # semi join = keeps the rows of A that have a match in B without adding B's columns 
  semi_join(fbs_teams, by = c("origin" = "school", "season" = "year")) |>
  semi_join(fbs_teams, by = c("destination" = "school", "season" = "year"))

# download stats for 21-26 
stats <- lapply(2021:2026, function(y) {
    get_cached(paste0("player_stats_", y), function() cfbd_stats_season_player(year = y))
}) |>
  bind_rows()

glimpse(stats) 

# coalesce(x, 0) -> turns blanks into 0, so a player with no catches doesn't break the math 
touches <- stats |>
    mutate(touches = coalesce(rushing_car, 0) + coalesce(receiving_rec, 0)) |>
    group_by(player, team, year) |>
    summarise(touches = max(touches), .groups = "drop")

skill <- skill |>
    # mutate = adds column to table ; season - 1 = year before transfer 
    mutate(player = paste(first_name, last_name), before_year = season -1) |>
    # left join = keeps every row on the left and attaches matching columns from right 
    left_join(touches, by = c("player", "origin" = "team", "before_year" = "year")) |>
    rename(touches_before = touches) |>
    left_join(touches, by = c("player", "destination" = "team", "season" = "year")) |>
    rename(touches_after = touches) |>
    mutate(usable = coalesce(touches_before, 0) >= 10 &
                    coalesce(touches_after, 0) >= 10 &
                    season <= 2025)

counts <- skill |>
# keeps only usable transfers 
    filter(usable) |>
    count(season, position) |>
    # turns intp a grid - one row per year, one column per position
    pivot_wider(names_from = position, values_from = n)
    
print(counts) 

