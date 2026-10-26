# CLAUDE.md — Gator Portal Evaluation Engine

> Claude Code reads this file automatically at the start of every session in this folder.
> It is the project's long-term memory. Keep it current: when a decision changes, update it here.
> Detailed docs live in `docs/`. Read them before doing anything non-trivial.

## Who I'm working with
- **Ava Savino** — junior, data science major in Gainesville (UF). Leads the women's basketball analytics team at the UF Sports Analytics Lab (SAL). Bartends on the side, so work time is limited and uneven.
- Has deployed a Shiny app to shinyapps.io before (the UF women's basketball "UF App"), so R + Shiny + rsconnect deployment is familiar ground.
- Codes in **VS Code** (not RStudio), on a **Mac** (zsh terminal).
- Prefers plain-language explanations: say what to do and why in simple words, one step at a time. Define jargon the first time it appears.

## What this project is
**Gator Portal Evaluation Engine** — an R/Shiny app that ranks college football transfer-portal players with a new predictive metric, the **Transfer Translation Score (TTS)**, builds a standardized profile for any player in seconds, and ends every profile with a **Florida Fit** section (value over Florida's current starter).

- **Audience:** Florida Gators football staff / front office ("the football people"). They originally asked Ava for a metric. She applied for a football analyst role last year, was told to build her resume, and this is the "here's a tool your front office doesn't have" project.
- **Deadline:** send **Friday Dec 4, 2026**; **Saturday Dec 5** is the spare day. Must land before the winter portal window.
- **Headline sentence the whole project exists to make true:**
  *"Last year I built a composite score. This year I built one that tests whether it is right."*

## How TTS differs from last year's RB Breakdown (2025)
| | 2025 RB Breakdown | TTS (2026) |
|---|---|---|
| Question | Who were the best RBs last season? | Whose production carries over after he transfers? |
| Type | Descriptive | Predictive |
| Weights | Hand-picked (.30/.30/.20/.15/.15), min-max normalized | Learned via ridge regression on 2022–2025 transfers |
| Opponent adj. | None | Every input opponent-adjusted |
| Small samples | Arbitrary 75-carry cutoff (a 96-carry back ranked 9th) | Empirical Bayes shrinkage + 80% range on every score |
| Proof | None | Out-of-sample backtest (train 2022–24, test 2025) |
| Team-specific | No | Value over Florida's incumbent |

Known flaws in v1 that this fixes: min-max scaling (one outlier sets the scale), arbitrary carry cutoff, YPC/success/first downs being the same signal counted ~3x, no opponent adjustment, no uncertainty, no receiving.

## Locked decisions (don't relitigate without Ava)
1. **Language: R.** Reason: `cfbfastR` gives college play-by-play with EPA pre-computed; Ava already deployed Shiny. (Python version of the plan was retired Oct 20.)
2. **Editor: VS Code** with the R extension (see `docs/vscode_setup.md`).
3. **Data: public only** — CFBD API via `cfbfastR`. Ava's SkillCorner experience is **basketball only**; she has **no football tracking data**. SkillCorner is a résumé credential, not a data source here. Lab ideas are allowed only if computable from public play-by-play and they pass the backtest; tracking-dependent ideas go in "Future work."
4. **Scope: RB only (decided Oct 25, 2026).** Phase 0 counts found 226 usable FBS→FBS RB transfers for 2022–2025 (≥10 touches before AND after), well over the ~100 needed. Keeps a clean comparison to last year. WR (289), QB (169), TE (56) are out of scope → memo "Future work." Every script, table, and app page is RB-only; don't add other positions.
5. **Training set = 2022–2025 transfers.** 2026 transfers are mid-season → they get *scored*, not trained on.
6. **The app never calls CFBD live.** It reads only finished files in `app/data/`.
7. **Florida is a setting:** `TEAM <- "Florida"` at the top of the Florida script, never hardcoded.
8. **Minimum viable project:** Phases 0–3 + a simple Player Profile page. **Never cut:** the backtest, the Player Profile page, the Limitations section.

## Stack
| Job | Tool |
|---|---|
| Data | `cfbfastR` (`cfbd_*` functions + `load_cfb_pbp()`) |
| Wrangling / charts | `tidyverse` (dplyr, tidyr, ggplot2) |
| Cache | `arrow` parquet in `cache/` |
| Opponent adj. + TTS weights | `glmnet` (`cv.glmnet(alpha = 0)`), `Matrix` for sparse design |
| App | `shiny` + `bslib` (`page_navbar`), `plotly`, `DT` |
| Name matching | `stringdist` |
| Deploy | shinyapps.io via `rsconnect` (same account as UF basketball app) |
| Reproducibility | `renv` |
| Memo | Quarto → PDF (`quarto install tinytex` if LaTeX complains) |
| Misc | `jsonlite` |

## Repo layout (target)
```
gator-portal-engine/
├── CLAUDE.md            ← this file
├── README.md            ← how to rerun (written Week 7)
├── progress_log.md      ← 1–2 lines per session: what I did, what's next
├── .Renviron            ← CFBD_API_KEY=...   (GITIGNORED)
├── .gitignore           ← includes .Renviron and cache/
├── renv.lock
├── R/
│   ├── loader.R         ← get_cached(name, fetch)
│   ├── 01_pull.R        → cache/*.parquet
│   ├── 02_player_seasons.R → data/player_seasons.parquet, data/transfers.parquet
│   ├── 03_adjust.R      → data/player_metrics.parquet
│   ├── 04_tts.R         → model, data/tts_2026.parquet, backtest results
│   ├── 05_florida.R     → data/uf_needs.json, data/uf_roster.parquet, fit numbers
│   └── fit.R            ← fit calculations used by 05
├── cache/               (gitignored)
├── data/
├── app/
│   ├── app.R            ← 4 pages: Portal Board, Player Profile, Florida Needs, Methodology
│   └── data/            ← copies of finished files the app reads
├── memo/memo.qmd        → memo.pdf
└── docs/                ← handoff docs (outline, schedule, decisions, setup)
```

## Key method details (quick reference)
- **Success:** 50% of needed yards on 1st, 70% on 2nd, 100% on 3rd/4th (use cfbfastR's `success`).
- **Explosive run:** pick one cutoff (e.g. 12+ yds) and never change it.
- **Situations:** early downs (1st/2nd); passing downs (2nd & long, 3rd/4th & long); short yardage (3rd/4th, ≤2 to go); red zone (inside opp 20).
- **Touch share** = player carries / team carries (stand-in for snap counts).
- **Opponent adjustment:** ridge on sparse `~ rusher + defense - 1`, `cv.glmnet(alpha=0)`, per season, `coef(fit, s="lambda.min")`. Fallback: simple schedule-strength subtraction (build first).
- **Shrinkage:** `(n*rate + k*avg)/(n + k)`; k per stat from split-half reliability.
- **Target:** adjusted EPA/play (carries+targets) at new school, min touches (e.g. 50); separate yes/no "earned playing time."
- **Baselines to beat:** raw prior-year EPA/carry; 247 portal rating.
- **Backtest headline:** train 2022–24, predict 2025, `ntile(pred, 4)`, top-quartile minus bottom-quartile actual production.
- **TTS** = predicted value as RB percentile (0–100). **80% range** = pred ± 1.28 × typical error, widened by 1/√carries. Flags: "small n", "wide range".
- **Florida needs:** need weight = 100 − UF percentile per situation, normalized to sum 1. Incumbent baseline blends 2025/2026 (e.g. 60% on 2026).
- **Fit outputs:** upgrade over UF starter (EPA/play), need-weighted fit 0–100, complement vs overlap, per-game impact.

## Data gotchas
- Match by **player ID** when possible; names collide. Use `anti_join()` to list unmatched; hand-fix the top ~30 by carries.
- cfbfastR EPA ≠ CFBD PPA (different models). Validate by rank correlation, not exact match.
- Function names can change between package versions — check `?fn` before assuming.
- shinyapps.io free tier has monthly active-hour limits; check before sending the link.

## Context worth knowing (verify before using in outreach)
- Florida replaced its staff after the 2025 season: HC **Jon Sumrall** (hired Nov 30, 2025), GM **Dave Caldwell** leads a new front office, OC **Buster Faulkner** came from Georgia Tech. So the pitch is "a tool your new front office doesn't have," not "you missed out."
- Possible hook: Ava's 2025 model's #1 RB was **Malachi Hosley (Georgia Tech)** — Faulkner's back. Verify before using.

## Working rules for Claude in this repo
- Read `progress_log.md` and the current week in `docs/schedule.md` at the start of a session; tell Ava which box is next.
- Do boxes in order; a box is done only when its "Done when" is true.
- End each session: commit + add 1–2 lines to `progress_log.md`.
- Never commit `.Renviron` or `cache/`. Never print the API key.
- Prefer simple, working code over clever code; comment the *why*.
- If behind schedule, use the cut list in `docs/schedule.md` — top first.
- When a decision changes, update the "Locked decisions" section above.
