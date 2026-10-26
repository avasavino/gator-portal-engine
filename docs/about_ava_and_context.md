# About Ava + Everything Claude Knew (memory export)

This rebuilds what Claude (claude.ai) had saved about Ava and this project. Treat it as background. Use details only when they help the task.

## Profile
- Name: **Ava Savino**. Junior in college, **data science** major, lives in **Gainesville, FL** (UF). Interested in sports analytics.
- Leads the **women's basketball analytics team** at the **UF Sports Analytics Lab (SAL)**.
- Has done work with **SkillCorner** — **basketball only**; no football tracking access.
- Works as a **bartender** (shifts can eat weekday work time).
- Summer 2026: media SDR intern at **Flowcode** (NYC) under Tim Armstrong; lists it on her résumé as "Media Intern."
- Also writes her own quiz questions as a teacher.

## How Ava likes to work
- Plain language, step by step, define jargon. "Done when" criteria on tasks.
- Codes in **VS Code** on a **Mac** (zsh). Earlier hit an error from typing R commands into zsh instead of an R session — always say *where* to type a command (R terminal vs shell terminal).
- Likes detailed PDFs/docs for plans; built-up history of v1 → v2 → v3 outlines.

## This project: football research project ("the app", "portal project")
- Building an app for "the football people," who originally asked her for a metric. Wants one part to be a ranking metric of her own, different from last year's.
- Plan: build the engine first, keep metrics modular so lab-developed (SAL) metrics can be tested via the backtest and added; draw on SkillCorner experience as a credential.
- Name: **Gator Portal Evaluation Engine**, metric **Transfer Translation Score (TTS)**. Deadline **Dec 5, 2026** (send Dec 4).
- Decided **R over Python** (Oct 20). Codes in **VS Code** rather than RStudio.
- Last year (2025): applied for a Gators football analyst role, did an interview project (the "RB Breakdown"), was rejected and told to build her résumé.

## History of decisions (chronological)
| Date | Decision |
|---|---|
| ~Sep 20, 2026 | Reframed pitch: Florida's 2025 staff is gone (Sumrall/Caldwell/Faulkner). Pitch = "a tool your new front office doesn't have." Original plan doc written (Python, Oct 6 start). |
| ~Oct 6, 2026 | Staff asked for a metric → TTS proposed (predictive, learned weights, opponent-adjusted, shrunk, ranges, backtest). Breakdown v2 (12 pp PDF, Python/Streamlit). |
| Oct 6, 2026 | SkillCorner = basketball only, public data only → nothing structural changes; tracking-dependent ideas → Future work; SkillCorner framed as credential. Check SAL data-sharing permissions before publishing any lab metric. |
| Oct 20, 2026 | Calendar built (Oct 20 → Dec 5). Switched to **R** (cfbfastR EPA saves days; Shiny deploy experience). Breakdown v3 (R) + R calendar PDFs. |
| Oct 20, 2026 | Couldn't find public info on what UF football analytics uses → ask contact ("R or Python?") in Saturday Oct 24 message. |
| Oct 20, 2026 | VS Code vs RStudio: both work. Claude had suggested RStudio might be easier for this project; Ava's working setup is VS Code (now moving everything to Claude in VS Code). |
| Oct 25, 2026 | **Scope locked: RB only.** Phase 0 count: 226 usable RB transfers 2022–25 (39/46/64/77 by year). WR/QB/TE → Future work. |

## Ava's other active work (don't mix into this repo unless asked)
- **NFL Big Data Bowl 2027** (Kaggle; Combine tracking → NFL performance). R in VS Code, git repo `NFL-Big-Data-Bowl`, with a partner via GitHub.
- **WBK-Analytics (UF SAL women's basketball):** leads the team. Repo copied by professor from the men's repo — much still points at men's data. Goal: get **UF App** running on women's data on **shinyapps.io** (not working on Coaches Challenge). Data on HiPerGator at `/blue/uf-sal/wbk-skill-corner-data/` (not reachable from laptop or shinyapps.io; uses RStudio on Open OnDemand or SSH). Gotchas: ten schools have "Florida" in the name → match Gators exactly or by team ID; date field is UTC → evening Eastern tipoffs land on the next day.
- Classes: STA 4210 (regression), SPM3012 Social Issues in Sport (Dr. Christine Wegner), an advertising class.
