# Does my EPA per carry agree with CFBD's numbers?
# Different models, so check whether they rank backs the same 

library(cfbfastR) 
library(dplyr) 
library(arrow) 
source("R/loader.R")

# CFBD's per-player PPA, 2024 RBs
ppa <- get_cached("ppa_players_20244_rb", function() {
        cfbd_metrics_ppa_players_season(year = 2024, position = "RB")
})

glimpse(ppa) 

# My numbers for 2024 (100+ carries)
mine <- read_parquet("data/player_seasons.parquet") |>
    filter(season == 2024, carries >= 100) |>
    select(rush_player_id, rusher_player_name, pos_team, carries, epa_per_carry) 

# Mine and CFBD's side by side
compare <- ppa |>
    mutate(rush_player_id = as.numeric(athlete_id)) |>
    select(rush_player_id, avg_PPA_rush) |>
    inner_join(mine, by = "rush_player_id")

# Rank agreement - 1 = exact same order, 0 = no relationship 
print(nrow(compare))
print(cor(compare$epa_per_carry, compare$avg_PPA_rush, method = "spearman"))