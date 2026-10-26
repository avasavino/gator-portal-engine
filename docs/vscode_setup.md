# VS Code + R setup (Mac) — one time

## 1. Install
- R from CRAN (if not already), Quarto CLI (quarto.org), Git.
- VS Code extensions: **R** (REditorSupport), **Quarto**, optionally **Shiny** (Posit).

## 2. R packages for the editor
Open an **R session** — not zsh. Either Cmd+Shift+P → "R: Create R terminal", or type `R` in the VS Code terminal and press Enter (prompt changes to `>`). Then:
```r
install.packages(c("languageserver", "httpgd"))
# if httpgd fails from CRAN:
install.packages("httpgd", repos = c("https://nx10.r-universe.dev", "https://cloud.r-project.org"))
```
In VS Code settings, turn on **R › Plot: Use Httpgd**.

> Common mistake: typing `install.packages(...)` into the zsh prompt (`%`). It must go into R (`>`).

## 3. Project packages
With the `gator-portal-engine` folder open, in the R terminal:
```r
renv::init()
install.packages(c("tidyverse","cfbfastR","arrow","glmnet","Matrix","jsonlite",
                   "shiny","bslib","plotly","DT","stringdist","rsconnect"))
renv::snapshot()
```

## 4. Daily use
- Run a line/selection: **Cmd+Enter** (auto-opens an R terminal if none).
- Run a whole script: `source("R/01_pull.R")`.
- App: `shiny::runApp("app")` in the R terminal.
- Memo: Quarto extension Preview, or `quarto render memo/memo.qmd --to pdf` in the **shell** terminal.
- Packages installed here also work if the folder is later opened in RStudio.
