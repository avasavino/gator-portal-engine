# One row per RB transfer, with his season before and after
# Reads: cache/portal_*.parquet, data/player_seasons.parquet
# Writes: data/transfers.parquet

library(dplyr)
library(arrow)

# Simplify a name so small spelling differences don't block a match:
# "Henry Parrish Jr." and "Henry Parrish" both become "henryparrish"
clean_name <- function(x) {
    x <- tolower(x)                                 # all lowercase
    x <- gsub(" (jr|sr|ii|iii|iv|v)\\.?$", "", x)   # drop Jr./Sr./II/III/IV/V at the end
    x <- gsub("[^a-z]", "", x)                      # drop anything that isn't a letter
    x
}

player_seasons <- read_parquet("data/player_seasons.parquet")

# All portal entries 2022-2026, RB only
portal <- lapply(2022:2026, function(y) read_parquet(paste0("cache/portal_", y, ".parquet"))) |>
    bind_rows() |>
    filter(position == "RB") |>
    mutate(
        player      = paste(first_name, last_name),
        name_key    = clean_name(player),
        before_year = season - 1
    )

# Stat table, renamed so columns match portals
ids <- player_seasons |>
    mutate(name_key = clean_name(rusher_player_name)) |>
    select(rush_player_id, name_key, origin = pos_team, before_year = season, carries_before = carries)

# Match: same cleaned name, same old school, played there the season before
matched <- portal |>
    inner_join(ids, by = c("name_key", "origin", "before_year")) |>
    group_by(season, player, origin) |>
    slice_max(carries_before, n = 1, with_ties = FALSE) |>
    ungroup()
# No match
unmatched <- portal |>
    anti_join(ids, by = c("name_key", "origin", "before_year"))

# Near misses: unmatched backs with a simillar name on old team's stat sheet 
near_misses <- unmatched |>
    inner_join(ids, by = c("origin", "before_year"), suffix = c("", "_stats"), relationship = "many-to-many") |>
    mutate(dist = stringdist::stringdist(name_key, name_key_stats))

# Same person, name spelled differently - checked by hand 
# Ex. "Cam Wiley" = "Cameron Wiley", "Jay Ducker" = "Jevyon Ducker"
SAME_PERSON_IDS <- c(5306988, 4869582, 4428858, 4693791, 4429709, 4431074, 4429652)

hand_fixed <- near_misses |>
    filter(dist <= 4, rush_player_id %in% SAME_PERSON_IDS) |>
    select(-name_key_stats, -dist)

# Add the hand-fixed backs to the matched list and take them off the unmatched list 
matched <- bind_rows(matched, hand_fixed)
unmatched <- anti_join(unmatched, hand_fixed, by = c("season", "player", "origin"))

# Atach his season before and after 
# Match transfers on ID 
stats <- player_seasons |>
    select(-rusher_player_name)

transfers <- matched |>
    filter(!is.na(destination)) |>
    left_join(stats, by = c("rush_player_id", "origin" = "pos_team", "before_year" = "season")) |>
    left_join(stats, by = c("rush_player_id", "destination" = "pos_team", "season"),
                suffix = c("_pre", "_post"))

# Save 
write_parquet(transfers, "data/transfers.parquet")
