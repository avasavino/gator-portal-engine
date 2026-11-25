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
