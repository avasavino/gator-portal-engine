# Progress Log

One or two lines per work session: what I did, what's next.

## 2026-10-20 (Tue)
- Planning finished in claude.ai: Breakdown v3 (R) + day-by-day calendar (R). Decided R over Python; working in VS Code. Moved project memory into this repo (CLAUDE.md + docs/).
- Next: Week 1 Tue box set — repo + folders, install packages, `renv::init()`, CFBD key in `.Renviron`, `.gitignore`. Then Wed: `R/loader.R`.


10/25 
- Complete columns = season, first_name, last_name, position, origin, transfer_date, eligibility 
- Columns with holes = destination, rating, stars 
- Players with no new school each year:

  | season | entries | no new school |
  |---|---|---|
  | 2022 | 2273 | 906 |
  | 2023 | 2502 | 895 |
  | 2024 | 3378 | 724 |
  | 2025 | 4499 | 729 |
  | 2026 | 4484 | 980 |

## 2026-10-25 (Sun)
- Wrote R/loader.R (get_cached) and R/01_pull.R (portal 2022–26, FBS teams 2021–26). Built R/00_counts.R.
- Usable FBS→FBS transfers (≥10 touches before AND after, name + school match):

  | season | QB | RB | TE | WR |
  |---|---|---|---|---|
  | 2022 | 35 | 39 | 3 | 58 |
  | 2023 | 37 | 46 | 12 | 62 |
  | 2024 | 53 | 64 | 21 | 76 |
  | 2025 | 44 | 77 | 20 | 93 |

Oct 25, 2026 
- Scope: RB only, because 226 usable RB transfers (well over 100) and it keeps a clean comparison to the 2025 RB Breakdown. WR (289) → Future work.
- Note: backtest test set = 77 RBs (2025) → ~19 per quartile, so the headline will be noisy. Counts are a floor; name mismatches get fixed Oct 30.
Can't use TE because not enough data (<100) 

Nov 3, 2026 
- Downloaded play-by-play 2021-2026 into cache/ (2026 frozen as of Oct 30). 2024 = 277,048 plays x 362 columns. 
- Column names I'll use: 
    - Run play? 'rush' (1 = yes) Runner: 'rusher_player_name', 'rush_player_id' Yards: 'yds_rushed' TD:  'rush_td'
    - Teams: 'pos_team' (offense), 'def_pos_team' (defense) Situation: 'down', 'distance'
    - Value: 'EPA', 'success' (1 = stayed on schedule) 
- Note: run plays include QBs (ex Jalen Milrow) -> filter RBs later.

Nov 9–10, 2026
- Built R/02_player_seasons.R → data/player_seasons.parquet (one row per player per team per season, 2021–2026).
  - Rushing: carries, EPA, EPA/carry, success rate, explosive rate (12+ yds, fixed), first downs, fumbles.
  - Receiving: catches, rec yds, rec EPA per catch. Per catch, not per target, because public PBP doesn't name the receiver on ~2/3 of incompletions.
  - Situations: early downs, passing downs (2nd & 8+, 3rd/4th & 5+), short yardage (3rd/4th & ≤2), red zone (inside 20).
  - Touch share = carries / team carries.
- Sanity checks pass: touch share ≤ 1, all rates ≤ 1, no duplicate player-seasons. Fixed a bug: some plays had the runner's ID but a blank name, which split players into 2 rows (2,918 duplicates). Now grouped by ID only.

Nov 20, 2026
- Built R/02b_transfers.R → data/transfers.parquet. Matched portal RBs to stat IDs by cleaned name (drops Jr./III, punctuation) + old school + season before; hand-fixed 7 nicknames (e.g. Cam/Cameron Wiley); ties broken by most carries.
- Portal RBs 2022–26: 1,269 · matched 869 · unmatched 400 (mostly backs with no carries the year before).
- 699 transfers landed somewhere; 605 have both before AND after stats, 94 have no after carries.
- Checked my EPA/carry vs CFBD PPA (2024, 253 backs with 100+ carries): Spearman 0.87. CFBD runs ~0.1/carry higher for everyone (different model scale), no big outliers. Added to memo → Data.
- Phase 1 done (Week 2). Next: Week 3 Mon — simple defense ratings.

Nov 24, 2026 
- Built R/03_adjust.R: simple defense ratings (avg EPA/carry allowed per defense-season) -> each back's schedule ease -> adj_epa_simple = EPA/carry - schedule ease. 
- 2024 check (200+ carries): toughest schedules = SEC/Big Ten backs (Sampson, Wisner), adjusted UP; easiest = FCS/G5 (Illinois State, UC Davis, Boise State), adjusted DOWN. Jeanty 0.223 -> 0.189, still elite. 
- Ridge opponent adjustment: runner + defense rated together per season with cv.glmnet(alpha = 0), for EPA, success rate, and explosive rate. 17,588 player-seasons, 2021–26.
- Fixed a ridge bug: glmnet's default rescaling made 1-carry backs get the MOST extreme ratings. standardize = FALSE fixes it, so low-carry backs now shrink most toward average.
- Picked adjustment: Using ridge because it repeats best year to year (Spearman, same-team backs w/ 100+ carries, n = 296: raw 0.259, simple 0.281, ridge 0.313). Simple kept as fallback. CFBD's adjusted metric (WEPA) needs a paid key (HTTP 401), so used this test instead.
- Fixed loader.R so it refuses to save empty downloads. Saved data/adjusted_simple.parquet + data/adjusted_ridge.parquet. Memo updated.

- Split-half test (R/00_split_half.R, RB plays 2021–25): k per stat for shrinkage
  - rec EPA per catch: r = 0.11 → k ≈ 75 catches
  - short-yardage conversion: r = 0.08 → k ≈ 90 attempts
  - fumble rate: r = 0.06 → k ≈ 900 touches (fumbles ≈ luck, matches prior research)
  - EPA, success, explosive already shrunk by ridge.

- Final components (R/03_adjust.R) → data/player_metrics.parquet: FBS RBs only (~650–740 per season, 2021–26). Ridge EPA/success/explosive; shrunk rec EPA per catch (k=75), short-yardage conv (k=90), fumble rate (k=900); touch share. Percentiles within season.
- 2024 top 10 by adjusted EPA = Jordan James, RJ Harvey, Skattebo, Woody Marks, Devin Neal, Jeanty, Hampton, Kaleb Johnson (≈ 2025 NFL Draft RB class). Jeanty 98th EPA but 7th receiving: pure runner.

