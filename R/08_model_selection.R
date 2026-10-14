# ==============================================================================
# SCRIPT 08: MODEL SELECTION & COINTEGRATION
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(vars)
  library(urca)
})

cat(">>> Memulai Tahap 8: Pemilihan Model, Lag Optimal, dan Uji Kointegrasi...\n")

panel_data <- readRDS("data/processed/panel_final.rds")
reg_df <- panel_data$regional_asean %>%
  filter(year >= 2011) %>%
  arrange(year, quarter)

# 1. DEFINISI VARIABEL ENDOGEN DAN EKSOGEN
endo_vars <- c("inflation_yoy", "gdp_growth", "money_growth", "reer_yoy")
exo_vars  <- c("oil_yoy", "fao_yoy", "ffr_change")

y_mat   <- as.matrix(reg_df[, endo_vars])
exo_mat <- as.matrix(reg_df[, exo_vars])

# 2. UJI LAG SELECTION (AIC, HQ, SC, FPE)
lag_sel <- VARselect(y_mat, lag.max = 4, type = "const", exogen = exo_mat)

lag_criteria_df <- tibble(
  lag = 1:4,
  aic = round(lag_sel$criteria["AIC(n)", ], 4),
  hq  = round(lag_sel$criteria["HQ(n)", ], 4),
  sc  = round(lag_sel$criteria["SC(n)", ], 4),
  fpe = round(lag_sel$criteria["FPE(n)", ], 6)
)

optimal_lags <- tibble(
  criterion = c("AIC (Akaike Information Criterion)", "HQ (Hannan-Quinn)", "SC / BIC (Schwarz Information Criterion)", "FPE (Final Prediction Error)"),
  optimal_lag = as.integer(lag_sel$selection),
  selected_for_model = c("Candidate", "Candidate", "Primary (Parsimonious Lag = 2)", "Candidate")
)

cat("=== KRITERIA PEMILIHAN LAG ===\n")
print(optimal_lags)
print(lag_criteria_df)

# 3. UJI KOINTEGRASI JOHANSEN (TRACE & MAXIMUM EIGENVALUE)
coint_trace <- ca.jo(y_mat, type = "trace", ecdet = "const", K = 2)
coint_eigen <- ca.jo(y_mat, type = "eigen", ecdet = "const", K = 2)

trace_stat <- coint_trace@teststat
trace_cval <- coint_trace@cval
r_hypotheses <- c("r <= 3", "r <= 2", "r <= 1", "r = 0")

coint_summary_df <- tibble(
  null_hypothesis = r_hypotheses,
  trace_statistic = round(trace_stat, 2),
  cval_10pct = round(trace_cval[, "10pct"], 2),
  cval_5pct  = round(trace_cval[, "5pct"], 2),
  cval_1pct  = round(trace_cval[, "1pct"], 2),
  decision = ifelse(trace_stat > trace_cval[, "5pct"], "Tolak H0 (Bukti Hubungan Jangka Panjang)", "Gagal Tolak H0")
)

cat("\n=== HASIL UJI KOINTEGRASI JOHANSEN ===\n")
print(coint_summary_df)

# Simpan hasil pemilihan model
dir.create("output", showWarnings = FALSE)
write.csv(lag_criteria_df, "output/ASEAN_Lag_Selection.csv", row.names = FALSE)
write.csv(coint_summary_df, "output/ASEAN_Cointegration_Test.csv", row.names = FALSE)

saveRDS(list(
  lag_selection = lag_sel,
  lag_criteria_df = lag_criteria_df,
  optimal_lags = optimal_lags,
  coint_trace = coint_trace,
  coint_eigen = coint_eigen,
  coint_summary_df = coint_summary_df,
  endo_vars = endo_vars,
  exo_vars = exo_vars,
  selected_lag = 2
), "data/processed/model_selection.rds")

cat(">>> Selesai Tahap 8. Hasil pemilihan model tersimpan di output/ASEAN_Lag_Selection.csv dan output/ASEAN_Cointegration_Test.csv\n")

