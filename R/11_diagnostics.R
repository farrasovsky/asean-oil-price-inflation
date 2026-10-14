# ==============================================================================
# SCRIPT 11: MODEL DIAGNOSTICS & SENSITIVITY ANALYSIS
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vars)
  library(plm)
})

select <- dplyr::select
filter <- dplyr::filter

cat(">>> Memulai Tahap 11: Uji Diagnostik Model dan Analisis Sensitivitas...\n")

irf_data <- readRDS("data/processed/irf_fevd_results.rds")
panel_data <- readRDS("data/processed/panel_final.rds")
reg_df <- panel_data$regional_asean %>% filter(year >= 2011) %>% arrange(year, quarter)
panel_final <- panel_data$panel_final %>% filter(year >= 2011) %>% arrange(country, year, quarter)

var_mod <- irf_data$var_ordered

# ------------------------------------------------------------------------------
# 1. DIAGNOSTIK MODEL UTAMA
# ------------------------------------------------------------------------------
# A. Stabilitas Sistem (Eigenvalue Companion Matrix)
comp_roots <- roots(var_mod)
max_root <- max(comp_roots)
is_stable <- all(comp_roots < 1)

# B. Autokorelasi Residual (Portmanteau Test)
st <- serial.test(var_mod, lags.pt = 10, type = "PT.asymptotic")

# C. Heteroskedastisitas (Multivariate ARCH Test)
at <- arch.test(var_mod, lags.multi = 4)

# D. Normalitas Residual (Multivariate Jarque-Bera Test)
nt <- normality.test(var_mod)

diag_summary_df <- tibble(
  diagnostic_test = c(
    "System Stability (Eigenvalues of Companion Matrix)",
    "Residual Autocorrelation (Portmanteau Test, lag=10)",
    "Heteroskedasticity (Multivariate ARCH Test, lag=4)",
    "Residual Normality (Multivariate Jarque-Bera Test)",
    "Residual Skewness Test",
    "Residual Kurtosis Test"
  ),
  statistic = c(
    round(max_root, 4),
    round(as.numeric(st$serial$statistic), 2),
    round(as.numeric(at$arch.mul$statistic), 2),
    round(as.numeric(nt$jb.mul$JB$statistic), 2),
    round(as.numeric(nt$jb.mul$Skewness$statistic), 2),
    round(as.numeric(nt$jb.mul$Kurtosis$statistic), 2)
  ),
  parameter_df = c(
    length(comp_roots),
    as.integer(st$serial$parameter),
    as.integer(at$arch.mul$parameter),
    as.integer(nt$jb.mul$JB$parameter),
    as.integer(nt$jb.mul$Skewness$parameter),
    as.integer(nt$jb.mul$Kurtosis$parameter)
  ),
  p_value = c(
    NA_real_,
    round(as.numeric(st$serial$p.value), 6),
    round(as.numeric(at$arch.mul$p.value), 4),
    round(as.numeric(nt$jb.mul$JB$p.value), 4),
    round(as.numeric(nt$jb.mul$Skewness$p.value), 4),
    round(as.numeric(nt$jb.mul$Kurtosis$p.value), 4)
  ),
  evaluation = c(
    ifelse(is_stable, "Sistem Stabil (Semua Modulus Akar < 1)", "Sistem Tidak Stabil"),
    ifelse(st$serial$p.value < 0.05, "Terdapat Autokorelasi Residual Dinamis", "Tidak Ada Autokorelasi Residual"),
    ifelse(at$arch.mul$p.value > 0.05, "Lolos Uji: Homoskedastisitas Terpenuhi (Tidak Ada Efek ARCH)", "Terdapat Heteroskedastisitas ARCH"),
    ifelse(nt$jb.mul$JB$p.value > 0.05, "Lolos Uji: Residual Berdistribusi Normal", "Residual Tidak Normal"),
    ifelse(nt$jb.mul$Skewness$p.value > 0.05, "Asimetri Simetris", "Asimetri Signifikan"),
    ifelse(nt$jb.mul$Kurtosis$p.value > 0.05, "Kurtosis Normal Mesokurtik", "Kurtosis Leptokurtik")
  )
)

cat("=== RINGKASAN DIAGNOSTIK MODEL UTAMA ===\n")
print(diag_summary_df)
write.csv(diag_summary_df, "output/ASEAN_Diagnostics.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 2. ANALISIS SENSITIVITAS & PERBANDINGAN MODEL
# ------------------------------------------------------------------------------
endo_vars <- c("gdp_growth", "money_growth", "reer_yoy", "inflation_yoy")
exo_vars  <- c("oil_yoy", "fao_yoy", "ffr_change")

y_mat   <- as.matrix(reg_df[, endo_vars])
exo_mat <- as.matrix(reg_df[, exo_vars])

# Sensitivitas 1: Lag 1 vs Lag 2 vs Lag 3
var_lag1 <- VAR(y_mat, p = 1, type = "const", exogen = exo_mat)
var_lag2 <- var_mod # Lag 2 (Model Terpilih)
var_lag3 <- VAR(y_mat, p = 3, type = "const", exogen = exo_mat)

# Sensitivitas 2: Sub-sampel Pre-COVID (2011-2019) vs Periode Penuh
reg_precovid <- reg_df %>% filter(year <= 2019)
y_precovid   <- as.matrix(reg_precovid[, endo_vars])
exo_precovid <- as.matrix(reg_precovid[, exo_vars])
var_precovid <- VAR(y_precovid, p = 2, type = "const", exogen = exo_precovid)

# Sensitivitas 3: Core Sample (Tanpa negara dengan imputasi mayor: mengecualikan Laos & Myanmar)
core_countries <- c("Indonesia", "Malaysia", "Brunei", "Thailand", "Singapore", "Philippines", "Vietnam", "Cambodia")
core_regional <- panel_final %>%
  filter(country %in% core_countries) %>%
  group_by(year, quarter, period) %>%
  summarise(
    gdp_growth = mean(gdp_growth, na.rm = TRUE),
    money_growth = mean(money_growth, na.rm = TRUE),
    reer_yoy = mean(reer_yoy, na.rm = TRUE),
    inflation_yoy = mean(inflation_yoy, na.rm = TRUE),
    oil_yoy = first(oil_yoy),
    fao_yoy = first(fao_yoy),
    ffr_change = first(ffr_change),
    .groups = "drop"
  )
y_core   <- as.matrix(core_regional[, endo_vars])
exo_core <- as.matrix(core_regional[, exo_vars])
var_core <- VAR(y_core, p = 2, type = "const", exogen = exo_core)

# Rangkum perbandingan koefisien pendorong inflasi lintas spesifikasi
extract_inf_eq <- function(v_obj, spec_name, n_obs) {
  s_obj <- summary(v_obj)
  eq_inf <- s_obj$varresult$inflation_yoy
  c_tab <- as.data.frame(eq_inf$coefficients)
  
  tibble(
    specification = spec_name,
    n_obs = n_obs,
    r_squared = round(eq_inf$r.squared, 4),
    adj_r_squared = round(eq_inf$adj.r.squared, 4),
    lag1_inf_coef = round(c_tab["inflation_yoy.l1", "Estimate"], 4),
    lag1_inf_pval = round(c_tab["inflation_yoy.l1", "Pr(>|t|)"], 4),
    oil_shock_coef = round(c_tab["oil_yoy", "Estimate"], 4),
    oil_shock_pval = round(c_tab["oil_yoy", "Pr(>|t|)"], 4),
    fao_shock_coef = round(c_tab["fao_yoy", "Estimate"], 4),
    fao_shock_pval = round(c_tab["fao_yoy", "Pr(>|t|)"], 4),
    ffr_shock_coef = round(c_tab["ffr_change", "Estimate"], 4),
    ffr_shock_pval = round(c_tab["ffr_change", "Pr(>|t|)"], 4)
  )
}

comp_df <- bind_rows(
  extract_inf_eq(var_lag2, "Model Utama: VARX(2) Full Sample (2011-2025)", nrow(reg_df)),
  extract_inf_eq(var_lag1, "Sensitivitas Lag 1: VARX(1)", nrow(reg_df)),
  extract_inf_eq(var_lag3, "Sensitivitas Lag 3: VARX(3)", nrow(reg_df)),
  extract_inf_eq(var_precovid, "Sensitivitas Periode: Pre-COVID (2011-2019)", nrow(reg_precovid)),
  extract_inf_eq(var_core, "Sensitivitas Imputasi: Core 8 Negara (Eksklusi Laos & Myanmar)", nrow(core_regional))
)

cat("\n=== TABEL PERBANDINGAN SENSITIVITAS SPESIFIKASI MODEL ===\n")
print(comp_df)
write.csv(comp_df, "output/ASEAN_Model_Comparison.csv", row.names = FALSE)

# Simpan objek diagnostik
saveRDS(list(
  diag_summary_df = diag_summary_df,
  comp_roots = comp_roots,
  model_comparison = comp_df,
  var_precovid = var_precovid,
  var_core = var_core
), "data/processed/diagnostics_results.rds")

cat(">>> Selesai Tahap 11. Hasil diagnostik dan perbandingan tersimpan di output/ASEAN_Diagnostics.csv dan output/ASEAN_Model_Comparison.csv\n")

