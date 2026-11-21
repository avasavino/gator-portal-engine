# 02_player_seasons.R — one row per player per season
# Reads: cache/pbp_*.parquet
# Writes: data/player_seasons.parquet

library(dplyr)
library(arrow)

# explosive run cutoff - fixed, never change
EXPLOSIVE_YDS <- 12

# turns one season of plays into one row per player
build_season <- function(y) {

    # Open the season's plays once - runs and catches both come from this
    pbp <- read_parquet(paste0("cache/pbp_", y, ".parquet"))

    # Keep only run plays that have a runner ID, then tag the situation of each run
    runs <- pbp |>
        filter(rush == 1, !is.na(rush_player_id)) |>
        mutate(
            early_down    = down %in% c(1, 2),
            passing_down  = (down == 2 & distance >= 8) | (down %in% c(3, 4) & distance >= 5),
            short_yardage = down %in% c(3, 4) & distance <= 2,
            red_zone      = yards_to_goal <= 20
        )

    # One pile per player, per team, per season. ID keeps players w/ same name apart
    rushing <- runs |>
        group_by(rush_player_id, pos_team, season) |>
        summarise(
            rusher_player_name  = first(na.omit(rusher_player_name)),
            carries         = n(),
            total_epa       = sum(EPA, na.rm = TRUE),
            epa_per_carry   = mean(EPA, na.rm = TRUE),
            success_rate    = mean(success, na.rm = TRUE),
            explosive_rate  = mean(yds_rushed >= EXPLOSIVE_YDS, na.rm = TRUE),
            first_downs     = sum(firstD_by_yards, na.rm = TRUE),
            fumbles         = sum(fumble_vec, na.rm = TRUE),
            early_carries   = sum(early_down, na.rm = TRUE),
            passing_carries = sum(passing_down, na.rm = TRUE),
            sy_carries      = sum(short_yardage, na.rm = TRUE),
            sy_success      = mean(success[short_yardage], na.rm = TRUE),
            rz_carries      = sum(red_zone, na.rm = TRUE),
            rz_success      = mean(success[red_zone], na.rm = TRUE),
            .groups = "drop"
        )

    # Catches only: public play-by-play doesn't name the receiver on most
    # incompletions, so true targets can't be counted
    receiving <- pbp |>
        filter(pass == 1, completion == 1, !is.na(reception_player_id)) |>
        group_by(reception_player_id, pos_team, season) |>
        summarise(
            catches       = n(),
            rec_yds       = sum(yds_receiving, na.rm = TRUE),
            rec_epa       = sum(EPA, na.rm = TRUE),
            epa_per_catch = mean(EPA, na.rm = TRUE),
            .groups = "drop"
        )

    # His share of the team's carries: our stand-in for snap counts (not public)
    team_carries <- runs |>
        count(pos_team, season, name = "team_carries")

    # Put it all together: one row per player-season
    rushing |>
        left_join(team_carries, by = c("pos_team", "season")) |>
        mutate(touch_share = carries / team_carries) |>
        left_join(receiving, by = c("rush_player_id" = "reception_player_id", "pos_team", "season"))
}

# Run the recipe for every season, then stack them into one table
player_seasons <- lapply(2021:2026, build_season) |>
    bind_rows()

# Save it so later scripts can read it
dir.create("data", showWarnings = FALSE)
write_parquet(player_seasons, "data/player_seasons.parquet")
