# How much should each stat be shrunk? (finds k for shrink())
# Randomly split each back's plays into two halves. If a stat is real skill, 
#   his two halves agree. The less they agree, the bigger k (more shrinking). 

library(dplyr) 
library(arrow) 

# Plays from 2021-2025 (2026 isn't finished), only the columns needed 
pbp <- lapply(2021:2025, function(y) {
    read_parquet(paste0("cache/pbp_", y, ".parquet"), 
                col_select = c("season", "rush", "pass", "completion", "rush_player_id", 
                                "reception_player_id", "down", "distance", "success", 
                                "EPA", "fumble_vec"))
}) |>
    bind_rows()

# Who's a running back each season (from the CFBD season stats you cached in Week 1)
rbs <- lapply(2021:2025, function(y) read_parquet(paste0("cache/player_stats_", y, ".parquet"))) |>
    bind_rows() |>
    filter(position == "RB") |>
    transmute(player = as.numeric(athlete_id), season = year) |>
    distinct()

# One row per play: who did it, and the outcome to measure 
catches <- pbp |>
    filter(pass == 1, completion == 1, !is.na(EPA)) |>
    transmute(player = reception_player_id, season, value = EPA) |>
    semi_join(rbs, by = c("player", "season"))

short_yardage <- pbp |>
    filter(rush == 1, !is.na(rush_player_id), down %in% c(3, 4), distance <= 2, !is.na(success)) |>
    transmute(player = rush_player_id, season, value = success) |>
    semi_join(rbs, by = c("player", "season"))

touches <- bind_rows(
    pbp |> filter(rush == 1, !is.na(rush_player_id)) |>
        transmute(player = rush_player_id, season, value = fumble_vec),
    pbp |> filter(pass == 1, completion == 1, !is.na(reception_player_id)) |>
        transmute(player = reception_player_id, season, value = fumble_vec)
) |>
    mutate(value = coalesce(value, 0)) |>
    semi_join(rbs, by = c("player", "season"))

# split_half_k(): split each back's plays into two random halves, see how well 
#   the halves agree, and turn that agreement into k (how hard to shrink) 
split_half_k <- function(plays, min_plays) {
    set.seed(2026) 
    halves <- plays |>
        group_by(player, season) |>
        filter(n() >= min_plays) |>
        mutate(half = sample(rep(1:2, length.out = n()))) |>
        group_by(player, season, half) |>
        summarise(rate = mean(value), n = n(), .groups = "drop") |>
        tidyr::pivot_wider(names_from = half, values_from = c(rate, n))
    
    r   <-  cor(halves$rate_1, halves$rate_2) 
    n_half  <- mean(c(halves$n_1, halves$n_2)) 
    tibble(backs = nrow(halves), r = r, n_half = n_half, k = n_half * (1 - r) /r)
}

k_values <- bind_rows(
    rec_epa_per_catch = split_half_k(catches, 10), 
    sy_success  = split_half_k(short_yardage, 10), 
    fumble_rate     = split_half_k(touches, 50), 
    .id = "stat"
)

print(k_values) 