# Build TTS: learn what predicts a back's production after he transfers 
# Reads: data/transfers.parquet, data/player_metrics.parquet
# Writes: model, data/tts_2026.parquet, backtest results (later this week)

library(dplyr) 
library(arrow) 

#"worked out" is only judged for backs with 50+ carries at new school 
MIN_CARRIES_AFTER <- 50

metrics <- read_parquet("data/player_metrics.parquet")

# FBS teams each season
fbs <- lapply(2021:2026, function(y) {
    read_parquet(paste0("cache/fbs_teams_", y, ".parquet")) |> mutate(season = y)
}) |>
    bind_rows() |>
    select(destination = school, season)

# What we know before the transfer - his last season at the old school
pre <- metrics |>
    transmute(rush_player_id, origin = pos_team, before_year = season, 
        carries_pre = carries, 
        epa_raw_pre = epa_per_carry, 
        ridge_epa_pre = ridge_epa, 
        ridge_success_pre = ridge_success, 
        ridge_explosive_pre = ridge_explosive, 
        rex_epa_pre = rec_epa_per_catch_shr, 
        sy_success_pre = sy_success_shr, 
        fumble_rate_pre = fumble_rate_shr, 
        touch_share_pre = touch_share)

# What happened after - first season at new school
post <- metrics |>
    transmute(rush_player_id, destination = pos_team, season,
            carries_post = carries, 
            ridge_epa_post = ridge_epa)

training <- read_parquet("data/transfers.parquet") |>
    filter(season <= 2025) |>
    select(rush_player_id, player, season, before_year, origin, destination, rating, stars) |>
    semi_join(fbs, by = c("destination", "season")) |>
    inner_join(pre, by = c("rush_player_id", "origin", "before_year")) |>
    left_join(post, by = c("rush_player_id", "destination", "season")) |>
    mutate( 
        carries_post    = coalesce(carries_post, 0L), 
        earned_playing_time     = carries_post >= MIN_CARRIES_AFTER,
        starter_pre     = touch_share_pre > 0.40
    )

