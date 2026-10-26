# Schedule — Gator Portal Engine (Oct 20 → Dec 5, 2026)

Day-by-day calendar, R version, adapted for **VS Code**. Every task has a time estimate and a **Done when**. Tick `[x]` only when "Done when" is true.

## Ground rules
- **7 weeks.** Send the finished project **Fri Dec 4**. **Sat Dec 5** is spare.
- **Time budget:** ~2 hrs on weekdays, 3–4 hrs Saturday. **Sunday = catch-up** (rest if on track). If a bartending shift or exam eats a day, slide its boxes to Sunday.
- Do boxes in order — each depends on the one above.
- If a box takes more than 2x its estimate: write exactly where you're stuck, move on, come back.
- End every session: **commit to GitHub** + 1–2 sentences in `progress_log.md`.
- Write the memo as you go (one memo box per week).
- **Minimum project:** Phases 0–3 + a simple Player Profile page. **Never cut:** backtest, Player Profile page, memo Limitations.

## VS Code translation notes
The original calendar was written for RStudio. Equivalents:
- "Run in the console" → run in the **R terminal** (Cmd+Enter on a line auto-opens one; or Cmd+Shift+P → "R: Create R terminal").
- "New RStudio Project from Git" → `git clone` the repo, then **File > Open Folder** in VS Code.
- "File > New Quarto Document" → create `memo/memo.qmd` by hand; render with the Quarto extension's **Preview/Render** or `quarto render memo/memo.qmd --to pdf` in a normal terminal.
- Shiny: `shiny::runApp("app")` in the R terminal (or the Shiny extension's Run button). Plots show via `httpgd`.

## Overview
| Week | Dates | Doing | Have by Sunday |
|---|---|---|---|
| 1 | Oct 20–25 | Setup + check data exists (Phase 0) | Repo, loader, count of usable transfers, scope decided |
| 2 | Oct 26–Nov 1 | Data foundation (Phase 1) | player_seasons + transfers tables, checked vs CFBD |
| 3 | Nov 2–8 | Fair comparison (Phase 2) | Opponent-adjusted, shrunk stats for every back |
| 4 | Nov 9–15 | Build + backtest TTS (Phase 3) | TTS, ranges, headline backtest number |
| 5 | Nov 16–22 | Florida layer (Phase 4) + profile page | UF needs, fit numbers, working Player Profile |
| 6 | Nov 23–29 | Finish app + deploy (Phase 5) | All 4 pages live at a link (Thanksgiving off) |
| 7 | Nov 30–Dec 5 | Memo, README, send (Phase 6) | Memo PDF, clean repo, message sent Dec 4 |

---

## Week 1 · Oct 20–25 · Set up and check the plan can work
**Goal:** find out if the data exists and decide positions. By Sunday: count of usable transfers + written scope.

### Tue Oct 20 — Set up workspace (~1.5 hrs)
- [ ] **Make the GitHub repo + open in VS Code** (20 min)
  - Create repo `gator-portal-engine`, clone it, open the folder in VS Code.
  - Make folders: `R/`, `cache/`, `data/`, `app/`, `memo/`.
  - *Done when:* folder is open in VS Code with those folders.
- [ ] **Install packages** (20 min)
  - In R terminal: `install.packages(c("tidyverse","cfbfastR","arrow","glmnet","jsonlite","shiny","bslib","plotly","DT","stringdist","rsconnect","renv"))` (plus `languageserver`, `httpgd` for VS Code).
  - Run `renv::init()` first if starting fresh (records package versions).
  - *Done when:* `library(cfbfastR); library(shiny)` runs with no error.
- [ ] **Get CFBD key and hide it** (20 min)
  - Free key at collegefootballdata.com.
  - `.Renviron` in project folder: `CFBD_API_KEY=your_key_here`. Restart R.
  - Add `.Renviron` and `cache/` to `.gitignore`.
  - *Done when:* `Sys.getenv("CFBD_API_KEY")` is not blank and `.Renviron` does not appear in a commit.
- [ ] **Start progress log** (5 min) — `progress_log.md` with date + "Set up repo." *Done when:* file exists.

### Wed Oct 21 — "Never download twice" loader (~2 hrs)
- [ ] **Write the loader** (1.5 hrs) — `R/loader.R` with `get_cached(name, fetch)`: (1) if `cache/<name>.parquet` exists, `arrow::read_parquet()` it; (2) else run `fetch()`; (3) `arrow::write_parquet()` then return. Comment the 3 steps. *Done when:* function exists with comment.
- [ ] **Test it** (20 min) — run twice: `get_cached("fbs_teams_2024", function() cfbd_team_info(year = 2024))`. *Done when:* file in `cache/` and 2nd call is instant / no internet.

### Thu Oct 22 — Pull transfer portal data (~2 hrs)
- [ ] **Download portal 2022–2026** (45 min) — `get_cached("portal_2024", function() cfbd_recruiting_transfer_portal(year = 2024))` per year; `bind_rows()`. *Done when:* one table, all entries 2022–2026.
- [ ] **Inspect it** (1 hr) — `glimpse()`; find name, old school, new school, position, date, rating. Count blank new-school rows (never landed → can't train on). *Done when:* log notes which columns are complete vs holey.

### Fri Oct 23 — Count usable transfers (~2 hrs)
- [ ] **FBS-to-FBS skill players** (45 min) — FBS list per year from `cfbd_team_info()`; keep rows where old AND new school are FBS and position ∈ RB/WR/TE/QB. *Done when:* filtered table.
- [ ] **Has a before AND after season** (1 hr) — `cfbd_stats_season_player()` (rushing + receiving). Usable = real stats season before and after. 2026 transfers are mid-season → scored later, not trained on. Training = 2022–2025. *Done when:* each transfer marked usable or not.
- [ ] **Count table** (15 min) — `count(year, position)` → `pivot_wider()`. *Done when:* table pasted in progress log.

### Sat Oct 24 — Decide scope + check with staff (~2 hrs)
- [ ] **Pick positions** (30 min) — need ~100+ usable transfers per position. Safe choice: **RB only**. Add WR only if count is big and won't slow you down. *Done when:* "Scope: RB only, because…" in log.
- [ ] **Send the one question** (20 min) — to football contact: *"Quick question before I build this: in portal season, is the bottleneck evaluating players well, or evaluating enough of them fast enough? Also, does your staff work more in R or Python?"* *Done when:* sent.
- [ ] **Start memo** (30 min) — `memo/memo.qmd` with headings: What TTS measures / Data / How it was built / Does it work (backtest) / Florida fit / Limitations. Write 3–4 sentences under Data + count table. *Done when:* file exists, Data started.

### Sun Oct 25 — Catch-up
- [ ] Finish anything left.
- [ ] If early: time `load_cfb_pbp(seasons = 2021)`.

---

## Week 2 · Oct 26–Nov 1 · Data foundation
**Goal:** two clean tables — one row per player-season, one per transfer. By Sunday: `player_seasons.parquet`, `transfers.parquet`.

### Mon Oct 26 — Download all plays (~2 hrs)
- [ ] **PBP 2021–2026** (45 min) — `load_cfb_pbp(seasons = …)` one season at a time via loader. Need 2021 (2022 transfers' "before"). *Done when:* every season in `cache/`.
- [ ] **Learn the columns** (1 hr) — `names(pbp)`: offense, defense, down, distance, yards to goal, play type, yards gained, rusher, receiver, EPA, success. Write names in log. *Done when:* you can point at one run and say who, how far, EPA.

### Tue Oct 27 — Rushing stats (~2 hrs)
- [ ] **Write definitions first** (20 min) — success (cfbfastR column), explosive cutoff (e.g. 12+ yds, never change). Put in memo → Data. *Done when:* written.
- [ ] **Rushing table** (1.5 hrs) — run plays; `group_by(rusher, team, season) |> summarise(...)`: carries, total EPA, EPA/carry, success rate, explosive rate, first downs, fumbles. Use player ID if available. *Done when:* one row per player-season; a known back looks right.

### Wed Oct 28 — Receiving + situations (~2 hrs)
- [ ] **Receiving for backs** (45 min) — pass plays by target: targets, catches, rec EPA, EPA/target. (New vs last year.) *Done when:* receiving columns exist.
- [ ] **Situation splits** (1 hr) — `case_when()` tags: early downs, passing downs, short yardage (3rd/4th ≤2), red zone (inside 20). Count carries + success per situation. *Done when:* you can say "Player X: 14% short-yardage carries, converted Y%."

### Thu Oct 29 — Finish player-season table (~2 hrs)
- [ ] **Touch share** (30 min) — player carries / team carries.
- [ ] **Join + save** (1 hr) — `left_join()` all; `write_parquet(x, "data/player_seasons.parquet")`.
- [ ] **Sanity checks** (30 min) — no player > team carries; no rate > 100%; `count(player, season) |> filter(n > 1)` returns nothing. *Done when:* all 3 pass.

### Fri Oct 30 — Transfer table (~2 hrs)
- [ ] **Match portal names to stat names** (1.5 hrs) — ID if both have it, else name + old school + position. `anti_join()` to list misses; hand-fix the big names. *Done when:* unmatched list, big names fixed.
- [ ] **Attach before/after** (30 min) — join season before + season after. Save `data/transfers.parquet`. *Done when:* one row per transfer + count of failed matches.

### Sat Oct 31 — Check vs CFBD (~2 hrs)
- [ ] **Compare 12 backs** (1.5 hrs) — your EPA/carry vs `cfbd_metrics_ppa_players_season()`. Different models → check rank agreement with `cor()`. Explain differences in 2–3 sentences; chase any big outlier. *Done when:* differences explained in writing.
- [ ] **Memo** (20 min) — definitions + this check into Data. *Done when:* Data section done.

### Sun Nov 1 — Catch-up
- [ ] Finish anything left. Commit. **Phase 1 done.**

---

## Week 3 · Nov 2–8 · Make the comparison fair
**Goal:** same scale for every back (conference + sample size). By Sunday: `player_metrics.parquet`.

### Mon Nov 2 — Defense ratings (~2 hrs)
- [ ] **Simple defense ratings** (1 hr) — avg EPA/carry allowed per defense-season; each back's schedule strength = avg of defenses faced.
- [ ] **Simple adjustment (safety net)** (1 hr) — adj EPA = back's EPA/carry − (how easy his defenses were vs avg). *Done when:* every back has simple adj EPA.

### Tue Nov 3 — Ridge adjustment (~2 hrs)
- [ ] **Ridge model** (1.5 hrs) — one row per run play, y = EPA; `X <- Matrix::sparse.model.matrix(~ rusher + defense - 1, data = runs)`; `cv.glmnet(X, y, alpha = 0)` per season; rusher coef from `coef(fit, s = "lambda.min")`. Mirrors cfbfastR team ratings. *Done when:* every back has ridge-adj EPA/carry.
- [ ] **Explain it** (20 min) — 3 coach-readable sentences in memo → How it was built.

### Wed Nov 4 — Pick adjustment (~2 hrs)
- [ ] **Compare simple vs ridge vs CFBD adj PPA for 20 backs** (1.5 hrs). If ridge is weird and unexplainable, use simple and say so. *Done when:* "Using ___ because ___." in log.
- [ ] **Apply to success + explosive rate** (30 min).

### Thu Nov 5 — Shrinkage (~2 hrs)
- [ ] **Understand formula** (20 min) — `shrunk = (n*rate + k*avg)/(n + k)`.
- [ ] **Find k per stat** (1.5 hrs) — split-half: randomly split each back's carries, compute stat per half, `cor()` across backs. High agreement → small k. *Done when:* k per stat in log.

### Fri Nov 6 — Final player stats (~2 hrs)
- [ ] **Components** (1.5 hrs) — per back-season, shrunk + adjusted: EPA/rush, success, explosive, rec EPA/target, short-yardage conv; plus touch share, ball security (fumbles/touch). Percentiles with `percent_rank() * 100`. Save `data/player_metrics.parquet`.

### Sat Nov 7 — Check it worked (~2 hrs)
- [ ] **Before/after test** (1 hr) — 3 backs <100 carries who looked amazing → move toward avg; 3 backs 250+ → barely move. Else revisit k.
- [ ] **Memo** (45 min) — finish "fair comparison": adjustment, shrinkage, k values, example.

### Sun Nov 8 — Catch-up
- [ ] Finish. Commit. **Phase 2 done.**

---

## Week 4 · Nov 9–15 · Build the score and prove it works (MOST IMPORTANT WEEK)
**Goal:** learn what predicts post-transfer production, build TTS, test on unseen transfers. By Sunday: headline backtest number.

### Mon Nov 9 — Define "worked out" (~2 hrs)
- [ ] **Target** (45 min) — adj EPA/play (carries + targets) at new school, min touches (e.g. 50 — write it down). Separate yes/no "earned real playing time." Into memo → Does it work.
- [ ] **Training table** (1 hr) — one row per usable 2022–2025 RB transfer. Inputs: pre-transfer shrunk+adj stats, touch share, starter flag (e.g. touch share > 40%; Texas Tech says starting experience matters most). Output: target. `drop_na()`.

### Tue Nov 10 — Baselines (~2 hrs)
- [ ] **Baseline 1:** raw unadjusted pre-transfer EPA/carry vs target, `cor()`.
- [ ] **Baseline 2:** 247 portal rating vs target.
- [ ] Log both. TTS must beat both, or say so honestly.

### Wed Nov 11 — Learn weights (~2 hrs)
- [ ] **Fit** (1.5 hrs) — `as.matrix()` inputs; `set.seed()`; `cv.glmnet(x, y, alpha = 0)` (standardizes by default).
- [ ] **Read weights** (30 min) — table from `coef(fit, s="lambda.min")`. Is receiving heavy (4for4)? Success above YPC? 2–3 sentences in memo.

### Thu Nov 12 — THE BACKTEST (~2.5 hrs)
- [ ] **Train 2022–24, `predict()` 2025** (1 hr).
- [ ] **Headline number** (1 hr) — `ntile(pred, 4)`; top-quartile vs bottom-quartile actual production. Sentence: *"Backs in TTS's top quarter produced ___ more EPA per play after transferring than backs in the bottom quarter."* Plus TTS cor vs both baselines. *Done when:* headline + small comparison table.
- [ ] **If TTS doesn't win:** try one fix (fewer inputs, stronger shrink). Still no → report honestly.

### Fri Nov 13 — 0–100 score with range (~2 hrs)
- [ ] **Score** (45 min) — TTS = predicted value as RB percentile.
- [ ] **80% range** (1 hr) — pred ± 1.28 × typical 2025 error, scaled by 1/√carries; convert ends to 0–100. e.g. "TTS 85, range 80–89."
- [ ] **Flags** (15 min) — "small n", "wide range".

### Sat Nov 14 — Score 2026 + key memo section (~3 hrs)
- [ ] **Retrain on all 2022–25, score every 2026 FBS RB** (1 hr) — portal not open yet, so rank all; filter to entrants later. Save `data/tts_2026.parquet`.
- [ ] **Backtest chart** (45 min) — ggplot, 4 bars by TTS quartile, height = actual production; should step up. `ggsave()`.
- [ ] **Memo: "Does it work?"** (1 hr) — lead with the result.

### Sun Nov 15 — Catch-up + checkpoint
- [ ] Finish. Commit. **Phase 3 done.**
- [ ] **Checkpoint:** >2 days behind → go to cut list now.

---

## Week 5 · Nov 16–22 · Make it Florida's + profile page
**Goal:** UF weaknesses, incumbents, value over starter, working Player Profile.

### Mon Nov 16 — Where is Florida weak? (~2 hrs)
- [ ] **UF percentiles** (1.5 hrs) — vs FBS: short-yardage conv, explosive run rate, 3rd-down success, red zone success, backfield rec EPA, ball security. Need = 100 − pct, normalized to sum 1. `jsonlite::write_json()` → `data/uf_needs.json`.
- [ ] **Make it a setting** (15 min) — `TEAM <- "Florida"` at top.

### Tue Nov 17 — Who does Florida have? (~2 hrs)
- [ ] **Incumbent baseline** — UF RBs + components; blend 2025/2026 with one weight (e.g. 60% on 2026); transfers in with no UF plays use old school. Mark projected starter (most touches). Save `data/uf_roster.parquet`.

### Wed Nov 18 — Fit numbers (~2 hrs), all in `R/fit.R`
- [ ] **Upgrade over starter** (30 min) — player pred EPA/play − starter's.
- [ ] **Need-weighted fit 0–100** (45 min) — Σ need weight × player situational percentile.
- [ ] **Complement vs overlap + per-game impact** (45 min) — impact = upgrade/play × starter carries/game → yards + first downs via league averages.

### Thu Nov 19 — App skeleton + profile header (~2 hrs)
- [ ] **Skeleton** (45 min) — `app/app.R`, `bslib::page_navbar()` with 4 `nav_panel()`s: Portal Board, Player Profile, Florida Needs, Methodology. Florida blue `#0021A5` / orange `#FA4616`. Copy finished files into `app/data/`. `shiny::runApp("app")`.
- [ ] **Profile top** (1 hr) — `selectizeInput()` name box; header (name, pos, school, class, plays); TTS tile + range (`bslib::value_box()`).

### Fri Nov 20 — Profile middle (~2 hrs)
- [ ] **Component bars** (45 min) — `plot_ly(type = "bar", orientation = "h")` of percentiles.
- [ ] **Usage, schedule, game log** (1 hr) — situation %, avg opp strength, per-game line with opp strength.

### Sat Nov 21 — Florida section (~3 hrs)
- [ ] **Florida Fit box** (1.5 hrs) — orange `card()`: upgrade, fit score, complement/overlap, per-game impact. Last line every time: *"What this cannot see: blocking, snaps, character, injuries."*
- [ ] **Test 5 players** (30 min) — star, backup, G5 back, small-sample back, current Gator.
- [ ] **Memo: Florida fit** (45 min).

### Sun Nov 22 — Catch-up
- [ ] Commit. **Phase 4 done — must-have project exists.**

---

## Week 6 · Nov 23–29 · Finish the app + put it online
**Goal:** Thanksgiving week, work packed Mon–Wed. By Sunday all 4 pages live.

### Mon Nov 23 — Portal Board (~2.5 hrs)
- [ ] **Ranked table** (1.5 hrs) — `DT::datatable()`: rank, player, school, TTS, 80% range, UF value, flags. Sidebar filters: position, conference, min plays, class. `radioButtons()` toggle overall TTS vs Florida value.
- [ ] **Link + export** (45 min) — `input$board_rows_selected` → `nav_select()` to Profile + fill name. `downloadButton()` + `downloadHandler()` CSV.

### Tue Nov 24 — Florida Needs + Methodology (~2.5 hrs)
- [ ] **Florida Needs** (1 hr) — UF percentile bars, need weights, RB depth chart.
- [ ] **Methodology** (1.25 hrs) — backtest chart, headline, weight table, limitations, memo link.

### Wed Nov 25 — Make it hard to break (~2 hrs)
- [ ] **Messy names** (1 hr) — `stringdist::amatch()` + "Did you mean…?"; `validate(need(...))` for too-few-plays.
- [ ] **10 bad inputs** (45 min) — typo, nickname, lineman, blank, fake name… *Done when:* survives all 10.

### Thu Nov 26 — Thanksgiving, off.
### Fri Nov 27 — Light/off; catch up only if behind.

### Sat Nov 28 — Deploy (~2 hrs)
- [ ] **Prepare** (30 min) — `renv::snapshot()`; everything the app reads is inside `app/`. Restart R, run fresh.
- [ ] **Deploy** (45 min) — same shinyapps.io account as UF basketball app: `rsconnect::deployApp("app", appName = "gator-portal-engine")`. Check monthly active-hours limit.
- [ ] **Test link** (30 min) — phone + someone else's laptop, every page.

### Sun Nov 29 — Catch-up
- [ ] **Phase 5 done. FEATURE FREEZE starts — fixes and writing only.**

---

## Week 7 · Nov 30–Dec 5 · Package and send
**Goal:** understandable in 5 minutes, checkable in an hour. Send Fri Dec 4.

### Mon Nov 30 — Finish memo (~2 hrs)
- [ ] **Fill gaps** (1 hr) — read top to bottom, ~5 pages.
- [ ] **Limitations** (1 hr) — no snap counts (touch share proxy), no blocking, no OL/defenders, nothing on character/health, survivorship (only players who played have "after"), small 2026 samples.

### Tue Dec 1 — Polish memo (~2 hrs)
- [ ] **First page** (45 min) — what TTS is, headline backtest number, *"Last year I built a composite score. This year I built one that tests whether it is right."*
- [ ] **Outside reader** (45 min) — someone in the lab explains TTS back in one sentence.
- [ ] **Render** (15 min) — `quarto render memo/memo.qmd --to pdf` (if LaTeX error: `quarto install tinytex`).

### Wed Dec 2 — Clean the code (~2 hrs)
- [ ] **Number scripts + README** (1 hr) — `01_pull.R` … `05_florida.R`. README: live link on top, then `renv::restore()`, add key, run scripts in order, `shiny::runApp("app")`.
- [ ] **Clean up** (30 min) — delete scratch, header comment on each script.
- [ ] **Fresh-copy test** (30 min) — clone into new folder, follow README exactly.

### Thu Dec 3 — Rehearse demo (~1.5 hrs)
- [ ] **Practice** (45 min) — friend names a back → profile in seconds with Florida section → Methodology backtest. 3 times, timed. *Done when:* under 2 min.
- [ ] **Fix only what broke** (45 min).

### Fri Dec 4 — SEND
- [ ] **Write message** (30 min) — one line on what it is, app link, backtest sentence, memo PDF attached, offer in-person walkthrough.
- [ ] **Final check + send** (30 min).

### Sat Dec 5 — Deadline / spare day.

---

## If you fall behind — cut in this order (stop once back on track)
1. Fuzzy name matching + CSV export → selectize box is enough.
2. Florida Needs page → put the chart in the memo.
3. Hand-fixing every unmatched name → top 30 backs by carries only.
4. Ridge opponent adjustment → use the simple version (Mon Nov 2), say so.
5. Complement/overlap + per-game impact → keep upgrade + fit score.
6. Portal Board toggle + filters → plain sorted DT table.
7. Putting the app online → demo locally with `runApp()`.

**Never cut:** the backtest, the Player Profile page, the Limitations section.

## Glossary
- **API** — a site you ask for data with code. CFBD is one.
- **cfbfastR** — R package for college football data incl. play-by-play with EPA.
- **Cache** — folder of saved downloads so you never download twice.
- **Parquet** — fast, small table file (arrow reads/writes).
- **Commit** — snapshot of code to GitHub.
- **renv** — records package versions so the project reruns the same anywhere.
- **EPA (PPA on CFBD)** — expected points added by a play.
- **Success rate** — % of plays staying on schedule (50/70/100%).
- **Explosive rate** — % of carries over your big-gain cutoff.
- **Touch share** — share of team carries; stands in for snaps.
- **Opponent adjustment** — removing how easy/hard the defenses were.
- **Ridge (glmnet)** — regression that keeps weights from going extreme; `alpha = 0`.
- **Shrinkage** — pulling small-sample numbers toward average.
- **Cross-validation** — testing on held-out chunks to pick settings; `cv.glmnet` does it.
- **Backtest** — train on old transfers, test on newer unseen ones.
- **Baseline** — the simple method to beat.
- **Percentile** — rank out of 100.
- **80% range** — ~80% sure the true score is inside; wider = less certain.
- **Shiny / shinyapps.io** — R web apps / hosting.
- **Quarto** — text + R code → PDF.
