# Run from the TEMPO project root:
#   Rscript tests/theme_smoke_test.R
# The test parses app.R without starting Shiny or loading study data.

stopifnot(file.exists("app.R"))
stopifnot(file.exists(file.path("www", "tempo-logo.png")))
invisible(parse(file = "app.R"))
code <- paste(readLines("app.R", warn = FALSE), collapse = "\n")

stopifnot(
  grepl('h1(class = "sr-only", "TEMPO")', code, fixed = TRUE),
  grepl('src = "tempo-logo.png"', code, fixed = TRUE),
  grepl('Therapy Effects across Multiple Psychological Outcomes', code, fixed = TRUE),
  grepl('gold <- "#C89A2B"', code, fixed = TRUE),
  grepl('charcoal <- "#34383F"', code, fixed = TRUE),
  grepl('scale_fill_gradient2(low = charcoal, mid = "#FFFFFF", high = gold', code, fixed = TRUE),
  !grepl('#176B70|#E78D79|Teal =|coral =', code, ignore.case = TRUE),
  grepl('actionButton("pred_run", "Predict outcomes"', code, fixed = TRUE),
  grepl('tabPanel("04  Integration"', code, fixed = TRUE)
)

cat("PASS: TEMPO app parses and contains the gold-white-charcoal theme.\n")
