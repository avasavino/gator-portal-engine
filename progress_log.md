# Progress Log

One or two lines per work session: what I did, what's next.

## 2026-10-20 (Tue)
- Planning finished in claude.ai: Breakdown v3 (R) + day-by-day calendar (R). Decided R over Python; working in VS Code. Moved project memory into this repo (CLAUDE.md + docs/).
- Next: Week 1 Tue box set — repo + folders, install packages, `renv::init()`, CFBD key in `.Renviron`, `.gitignore`. Then Wed: `R/loader.R`.


10/25 
- Complete columns = season, first_name, last_name, position, origin, transfer_date, eligibility 
- Columns with holes = destination, rating, stars 
- Num of players with no new school each year =    <int>   <int>         <int>
1   2022    2273           906
2   2023    2502           895
3   2024    3378           724
4   2025    4499           729
5   2026    4484           980

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

Nov 20, 2026
- Checked my EPA/carry vs CFBD PPA (2024, 253 backs with 100+ carries): Spearman 0.87. CFBD runs ~0.1/carry higher for everyone (different model scale), no big outliers. Added to memo → Data.
- Phase 1 done (Week 2). Next: Week 3 Mon — simple defense ratings.
