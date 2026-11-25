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
# --- Ridge adjustment ------------------------------------------------------
# Rates every runner AND every defense at the same time, so neither rating
# is thrown off by who they happened to play. Same method as cfbfastR's team ratings.
library(Matrix)
library(glmnet)

# Explosive run cutoff - same as 02_player_seasons.R, never change
EXPLOSIVE_YDS <- 12

# ridge_ratings(): runs ridge on ONE outcome, returns each runner's rating
# (his result per carry with the defenses removed)
ridge_ratings <- function(X, outcome) {
    set.seed(2026)
    fit <- cv.glmnet(X, outcome, alpha = 0, standardize = FALSE)
    b <- as.matrix(coef(fit, s = "lambda.min"))
    b <- b[startsWith(rownames(b), "rusher"), 1]
    tibble(rush_player_id = as.numeric(sub("rusher", "", names(b))), rating = b)
}

# ridge_adjust(): for one season, adjusts EPA, success, and explosive rate
ridge_adjust <- function(y) {
    runs <- read_parquet(paste0("cache/pbp_", y, ".parquet")) |>
        filter(rush == 1, !is.na(rush_player_id), !is.na(EPA), !is.na(def_pos_team),
               !is.na(success), !is.na(yds_rushed)) |>
        mutate(
            rusher    = factor(rush_player_id),
            defense   = factor(def_pos_team),
            explosive = as.numeric(yds_rushed >= EXPLOSIVE_YDS)
        )

    # One row per carry, one column per runner and per defense (mostly zeros)
    X <- sparse.model.matrix(~ rusher + defense - 1, data = runs)

    # Same model three times, each predicting a different stat
    epa  <- ridge_ratings(X, runs$EPA)       |> rename(ridge_epa = rating)
    succ <- ridge_ratings(X, runs$success)   |> rename(ridge_success = rating)
    expl <- ridge_ratings(X, runs$explosive) |> rename(ridge_explosive = rating)

    epa |>
        left_join(succ, by = "rush_player_id") |>
        left_join(expl, by = "rush_player_id") |>
        mutate(season = y)
}

# Run ridge for every season and stack them
ridged <- lapply(2021:2026, ridge_adjust) |>
    bind_rows()

# Save both adjustments so later steps don't have to wait ~30 min to rebuild them
write_parquet(adjusted, "data/adjusted_simple.parquet")
write_parquet(ridged, "data/adjusted_ridge.parquet")

# One row per RB per season: every stat adjusted (ridge) or shrunk, plus percentiles
# shrink(): pull a small-sample rate toward the avg. k = how many 
#   "avg plays" to mix in (from the split-half test)
shrink <- function(rate, n, avg, k) {
    rate <- coalesce(rate, avg)
    n <- coalesce(n, 0)
    (n * rate + k * avg) / (n + k) 
}

#catches 
K_REC_EPA <- 75
#short-yardage attempts 
K_SY <- 90
#carries 
K_FUMBLE <- 900

# Who's a RB each season
rbs <- lapply(2021:2026, function(y) read_parquet(paste0("cache/player_stats_", y, ".parquet"))) |>
    bind_rows() |>
    filter(position == "RB") |>
    transmute(rush_player_id = as.numeric(athlete_id), season = year) |>
    distinct()

# FBS teeams each season
fbs <- lapply(2021:2026, function(y) {
    read_parquet(paste0("cache/fbs_teams_", y, ".parquet")) |> mutate(season = y) 
}) |>
    bind_rows() |>
    select(pos_team = school, season)

player_metrics <- read_parquet("data/player_seasons.parquet") |>
    semi_join(rbs, by = c("rush_player_id", "season")) |>
    semi_join(fbs, by = c("pos_team", "season")) |>
    left_join(ridged, by = c("rush_player_id", "season")) |>
    group_by(season) |>
    mutate(
        # RB avg that season
        avg_rec_epa = sum(rec_epa, na.rm = TRUE) / sum(catches, na.rm = TRUE), 
        avg_sy = sum(sy_success * sy_carries, na.rm = TRUE) / sum(sy_carries), 
        avg_fumble = sum(fumbles) / sum(carries),

        # Shrunk versions of the stats ridge didn't cover
        rec_epa_per_catch_shr = shrink(epa_per_catch, catches, avg_rec_epa, K_REC_EPA), 
        sy_success_shr = shrink(sy_success, sy_carries, avg_sy, K_SY), 
        fumble_rate_shr       = shrink(fumbles / carries, carries, avg_fumble, K_FUMBLE),
        
        # Percentiles (0-100) among FBS running backs that season
        pct_epa       = percent_rank(ridge_epa) * 100,
        pct_success   = percent_rank(ridge_success) * 100,
        pct_explosive = percent_rank(ridge_explosive) * 100,
        pct_receiving = percent_rank(rec_epa_per_catch_shr) * 100,
        pct_short_yds = percent_rank(sy_success_shr) * 100,
        pct_ball_sec  = percent_rank(-fumble_rate_shr) * 100,
        pct_touch     = percent_rank(touch_share) * 100
    ) |>
    ungroup() |>
    select(-starts_with("avg_"))

write_parquet(player_metrics, "data/player_metrics.parquet")
