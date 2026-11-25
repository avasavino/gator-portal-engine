# Make every back's numbers fair for the defenses ha faced 
# Reads: cache/pbp_*.parquet, data/player_seasons.parque
# Writes: data/player_metrics.parquet 

library(dplyr) 
library(arrow) 

# For one season, rate every run defense, then adjust each back's EPA/carry 
simple_adjust <- function(y) {
    runs <- read_parquet(paste0("cache/pbp_", y, ".parquet")) |>
        filter(rush == 1, !is.na(rush_player_id), !is.na(EPA))

    # Step 1: rate each defense = avg EPA per carry it allowed 
    # higher = easier to run on 
    defense <- runs |>
        group_by(def_pos_team) |>
        summarise(def_epa_allowed = mean(EPA), .groups = "drop")
   
    league_avg <- mean(runs$EPA)

    # Step 2: for each back, abg the ratings of the defense he ran against 
    # one entry per carry, so a defense he faced 20 times counts 20 times 
    runs |>
        left_join(defense, by = "def_pos_team") |>
        group_by(rush_player_id, pos_team, season) |>
        summarise(
                epa_per_carry = mean(EPA), 
                sched_ease = mean(def_epa_allowed) - league_avg, 
                .groups = "drop"
        ) |>
        # Step 3: remove the head start from schedule 
        mutate(adj_epa_simple = epa_per_carry - sched_ease)
}

adjusted <- lapply(2021:2026, simple_adjust) |>
    bind_rows()