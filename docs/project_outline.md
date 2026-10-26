# Project Outline — Gator Portal Evaluation Engine (Breakdown v3, R)

Prepared by Ava Savino · October 2026 · Target delivery **Dec 4, 2026** (before the winter transfer portal window)

> v3 changes from v2: all code in R (cfbfastR, tidyverse, glmnet, Shiny) instead of Python; schedule runs Oct 20 → Dec 4 instead of Oct 6 → Nov 30.

## 1. The project in one page
A web app that ranks transfer-portal players with a new metric, generates a standardized evaluation profile for any player in seconds, and ends every profile with a section showing what that player would add to **Florida's** roster.

Three connected parts:
- **The metric — Transfer Translation Score (TTS).** One number estimating how much of a player's production will carry over to a new team. Weights learned from every FBS transfer since 2022 (not hand-picked). Ships with an uncertainty range.
- **The profile engine.** Name in → full evaluation out: opponent-adjusted production, usage, schedule context, game log, same layout every time.
- **The Florida layer.** Florida's statistical needs + incumbent players → value over current UF starter and a need-weighted fit score.

**The sentence the project is built to say:** *"Last year I built a composite score. This year I built one that tests whether it is right."* The backtest makes it true and is the most important output.

### Why this answers the original request
The staff asked for a metric. v1 of the plan avoided ranking anyone; v2/v3 put a metric back at the center, but one that differs *in kind* from 2025:

| | 2025 RB Breakdown | TTS |
|---|---|---|
| Question | Best RBs last season? | Whose production carries over after transfer? |
| Type | Descriptive | Predictive |
| Weights | Hand-chosen (.30/.30/.20/.15/.15) | Learned from past transfers' before/after |
| Opponent adjustment | None | Every input |
| Small samples | 75-carry cutoff; 96-carry back ranked beside 250-carry backs | Shrinkage + uncertainty range |
| Proof | None | Backtest on 2022–2025 transfers, one number |
| Team-specific | No | Value over Florida's incumbent |

### What went wrong in v1 (2025) — to cite in the memo as self-audit
- Min-max normalization: one outlier (Isaac Brown, 8.5 YPC on 96 carries) set the scale and compressed everyone else → use percentiles/z-scores.
- 75-attempt cutoff arbitrary → empirical Bayes shrinkage instead.
- YPC, success rate, first downs ≈ same signal; weights effectively ~75% on one correlated factor.
- No opponent adjustment, no uncertainty, no receiving.

## 2. Layout
| Piece | What | For |
|---|---|---|
| The app | 4-page Shiny app on shinyapps.io, runs in browser | Analysts/personnel during portal season |
| Methods memo | ~5 pages, Quarto → PDF: what TTS measures, how built, backtest, limitations | Whoever decides whether to trust the numbers |
| Code repo | Clean, commented, numbered R scripts on GitHub + renv lockfile + README | Anyone checking the work |

### App pages
| Page | Purpose | Contents |
|---|---|---|
| 1. Portal Board | Ranked list (front page) | Filters (position, conference, min plays, class); toggle overall TTS vs Florida value; rows: score, range, UF value, flags |
| 2. Player Profile | Full evaluation | Header, TTS tile + range, component bars, usage, schedule context, game log, Florida Fit at bottom |
| 3. Florida Needs | The baseline behind fit | UF percentile vs FBS per situation, need weights, incumbent depth chart |
| 4. Methodology | Trust | Backtest chart, learned weights + meaning, limitations, memo link |

### Data flow (one direction)
raw PBP → clean player tables → opponent adjustment + shrinkage → TTS model (trained on past transfers) → scores for current players → joined with Florida baseline → app pages. Each arrow = one numbered R script. Florida is a setting (`TEAM <- "Florida"`), so the tool runs for any program.

| Script | Reads | Writes |
|---|---|---|
| `R/01_pull.R` | CFBD API + cfbfastR PBP (via cache) | `cache/*.parquet` |
| `R/02_player_seasons.R` | cached plays, portal entries | `data/player_seasons.parquet`, `data/transfers.parquet` |
| `R/03_adjust.R` | player seasons | `data/player_metrics.parquet` |
| `R/04_tts.R` | metrics, transfers | model, `data/tts_2026.parquet`, backtest results |
| `R/05_florida.R` | TTS, UF team stats | `data/uf_needs.json`, `data/uf_roster.parquet`, fit numbers |
| `app/app.R` | only `app/data/` | the four pages |

## 3. What it looks like (wireframe spec; numbers are placeholders)
Colors: Florida blue `#0021A5`, orange `#FA4616`.

**Portal Board:** top navbar (GATOR PORTAL ENGINE | Portal Board | Player Profile | Florida Needs | Methodology). Left sidebar: Position RB, Conference All, Min plays 100, Class Any, ranking view radio (Overall TTS / Florida value). Table: `# | Player | School | TTS | 80% range | UF value | Flag` (e.g. `2 | Player B | School X | 88 | 71–95 | +0.09 | small n`). Footer: click row → profile; sortable; Download CSV; refreshed weekly. Range + flags sit beside score so a 90-carry high score reads as riskier than a 250-carry one.

**Player Profile:**
- Blue header: `PLAYER A | RB | School W | Jr. | 5'11" 205` / entered portal date, plays in sample, opponent-adjusted.
- Row: TTS tile (big "91", 80% range 84–96, Confidence High) | "What drives the score" percentile bars (Adj EPA/rush 92, Success 85, Explosive 78, Rec EPA/target 70, Short-yardage 88) | Usage (early downs 58%, short yardage 14%, passing downs 19%, red zone 9%).
- Schedule context + game log (avg opp run D percentile; per-game line with opp strength).
- Orange **Florida Fit** box: upgrade over projected UF starter (+0.11 EPA/rush), need-weighted fit (74/100, UF weakest in short yardage + explosives), complement vs overlap, projected impact (~+9 rush yds, +0.6 first downs/game). Last line always: *What this cannot see: blocking, snaps, character, injuries.*

**Interview demo:** hand over laptop → they name any portal player → profile in seconds with Florida section → open Methodology → show backtest.

## 4. Tools
### Data
| Source | Provides | Notes |
|---|---|---|
| CFBD API via `cfbd_*` | rosters, games, portal entries (origin, destination, position, dates), recruiting ratings, season player stats | Free key as `CFBD_API_KEY` in `.Renviron`. Same source as 2025. Verify portal function first. |
| `load_cfb_pbp()` | FBS PBP with EPA, success, WP back to 2014 | Free, no key. Main PBP source; no hand-built EPA. |
| CFBD opponent-adjusted player PPA | adjusted rushing/passing value | Benchmark; different model → independent check |
| Coaching changes | which programs changed HCs | No clean endpoint; hand-code |

### Software (all R)
R in VS Code · tidyverse · cfbfastR · arrow (parquet cache) · glmnet + Matrix · hand-written empirical Bayes shrinkage · Shiny + bslib + plotly + DT · shinyapps.io via rsconnect (same platform as UF women's basketball app) · stringdist · renv · Quarto · GitHub.

### What public data can't provide (state up front)
- Snap counts → touch share proxy.
- Blocking → no public yards-before-contact; show OL context beside the number rather than claim to remove it.
- OL and defensive players → out of scope.
- Character, health, scheme knowledge → not measurable; said on every profile.

## 5. Prior work
**Closest models**
- **EvanMiya (college basketball):** projects portal transfers' value with a Bayesian, opponent/usage-adjusted rating; publicly checked projections vs results and vs human rankings. → closest analog; template for presenting a backtest.
- **Bill Connelly, SP+ returning production (ESPN):** folds transfers' prior production into team projections. → TTS is the player-level version and tests how much actually carries over.
- **TransferPortl (The Spade, Substack):** CFBD-based 2021–2026 portal site; logistic regression on who transfers + percentile grade. → shows CFBD portal data is workable; its grade isn't validated prediction (the gap TTS fills).
- **Georgia Tech ISyE capstone:** predicted portal entries, simulated GT roster turnover. → programs value student work framed around one team.

**Do transfers produce?**
- **Kovar & Bame-Aldred (U. Oregon):** PFF grades; benefit depends on position (QBs/interior OL outperformed recruits; LBs underperformed). → fit TTS by position.
- **David Hale (ACC 2024–25):** of 62 ACC transfers with real playing time, by his estimate more than half declined. → metric must be predictive.
- **Beyond the Score (Substack):** portal ratings added little once returning PPA included. → recruiting-service ratings are weak; production-based validated metric is where value is.
- **Joey McGuire, Texas Tech (Long Angle):** analytics filter; prior starting experience strongest predictor. → include starter flag + sample size.

**Which stats are stable?**
- **Football Perspective (NFL):** rushing efficiency barely repeats; success rate somewhat better than YPC/EPA. → favor stable stats; TTS learns this.
- **4for4 (NFL RB):** receiving stats most repeatable; rushing success barely predicts. → receiving must be in (2025 left it out).
- **cfbfastR team ratings:** ridge-based opponent-adjusted EPA. → method to copy, same language.

**Gap filled:** football has team-level transfer adjustments (SP+) and transfer-probability models; basketball has validated player transfer projections (EvanMiya). A public, validated, player-level CFB transfer projection tied to one team's needs is open space.

## 6. Phases (see `schedule.md` for day-by-day)
**Phase 0 — Confirm the plan holds (Oct 20–25).** Data exists? Staff wants it?
- Set up project (GitHub, packages, `renv::init()`, key in `.Renviron`). → project runs; key hidden
- Pull portal 2022–2026 via `cfbd_recruiting_transfer_portal()` + cache; check completeness; count FBS→FBS skill transfers with full before/after. → written count by year × position
- Decide scope (default RB only). → scope written
- Ask the building: bottleneck = evaluating well, or evaluating enough fast enough? → one-sentence answer

**Phase 1 — Data pipeline (Oct 26–Nov 1).**
- `get_cached(name, fetch)` loader → `cache/` + `R/loader.R`
- PBP 2021–2026 via `load_cfb_pbp()` → all seasons cached
- Player-season table (carries, targets, EPA, success, explosives, first downs, fumbles, situations, touch share) → `player_seasons.parquet`
- Transfer table (ID, old, new, year + before/after stats) → `transfers.parquet`
- Validate a dozen players vs CFBD player PPA → differences explained

**Phase 2 — Fair comparison (Nov 2–8).**
- Opponent adjustment: ridge `cv.glmnet(alpha=0)` on sparse rusher+defense; simple schedule-strength fallback first → `R/03_adjust.R`
- Shrinkage toward position mean, k per stat via split-half → `shrink()`
- Components + FBS percentiles → `player_metrics.parquet`

**Phase 3 — Build + backtest (Nov 9–15).**
- Target: adj EPA/play at new school, min-play threshold; separate playing-time flag → in memo
- Fit weights via ridge by position → model + weight table
- Backtest: train 2022–24, test 2025; top vs bottom quartile → headline number
- Beat raw prior production + 247 ratings? If not, say so → comparison table
- 80% ranges → on every player

**Phase 4 — Florida baseline + fit (Nov 16–18).**
- UF needs by situation → `uf_needs.json`
- Incumbent baseline (blend 2025/2026) → `uf_roster.parquet`
- Upgrade, need-weighted fit, complement/overlap, per-game impact → `R/fit.R`

**Phase 5 — App (Nov 19–29, Thanksgiving off).**
- Player Profile first (minimum project) → Portal Board → Needs + Methodology → hardening (stringdist, `validate(need())`) → deploy `rsconnect::deployApp()`

**Phase 6 — Write-up + send (Nov 30–Dec 4).**
- Memo (Quarto → PDF, ending in Limitations) · README + cleanup · outreach message Dec 4 · Dec 5 spare

## 7. Risks
| Risk | Handling |
|---|---|
| Too few transfers per position | Phase 0 counts first; RB only, or pool with position adjustment |
| Survivorship (only players who played have "after") | Model playing time separately, or state the bias plainly |
| Small 2026 UF samples | Blend 2025/2026 with adjustable weight; widen early ranges |
| TTS doesn't beat baselines | Report honestly; negative result > unvalidated score |
| Model disagrees with staff | Tool produces evaluations, not decisions |
| shinyapps.io hours run out | Check plan limit; keep local `runApp()` demo ready |
| Running out of time | Phases 0–3 + simple profile = minimum; cut app polish |

## 8. Sources
1. EvanMiya, Which Schools Get The Most Out Of Transfers — https://blog.evanmiya.com/p/which-schools-get-the-most-out-of
2. EvanMiya, Transfer Success Stories — https://blog.evanmiya.com/p/transfer-success-stories
3. EvanMiya, New Tool: Player Skill Projections — https://blog.evanmiya.com/p/new-tool-player-skill-projections
4. Connelly, 2025 returning production — https://abc7news.com/post/college-football-2025-returning-production-136-fbs-teams/15951013/
5. Connelly, returning production 2026 — https://abc7.com/post/what-returning-production-looks-like-2026-college-football-season/18754857/
6. TransferPortl — https://thespade.substack.com/p/transferportl-predicting-college
7. Georgia Tech ISyE Capstone — https://capstone.isye.gatech.edu/node/6008
8. U. Oregon, Analyzing the football transfer portal — https://business.uoregon.edu/news/analyzing-football-transfer-portal
9. David Hale, Greener pastures — https://davidhale.substack.com/p/greener-pastures
10. Beyond the Score — https://beyondthescoresports.substack.com/p/does-success-in-the-transfer-portal
11. Long Angle (Joey McGuire) — https://www.longangle.com/navigating-wealth-podcast/college-football-transfer-portal
12. Football Perspective, Rushing EPA and YPC — https://footballperspective.com/rushing-epa-and-yards-per-carry
13. 4for4, Most Predictable RB Stats — https://www.4for4.com/2024/preseason/most-predictable-running-back-stats
14. cfbfastR load_cfb_ratings — https://rdrr.io/cran/cfbfastR/man/load_cfb_ratings.html
15. cfbfastR overview — https://www.rdocumentation.org/packages/cfbfastR/versions/1.9.0
16. CollegeFootballData.com — https://collegefootballdata.com/
