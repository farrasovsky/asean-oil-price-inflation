# ==============================================================================
# SCRIPT 07: CROSS-SECTIONAL DEPENDENCE & STATIONARITY TESTS
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(plm)
  library(tseries)
  library(urca)
})

cat(">>> Memulai Tahap 7: Uji Ketergantungan Lintas Bagian dan Stasioneritas...\n")

panel_data <- readRDS("data/processed/panel_final.rds")
panel_final <- panel_data$panel_final %>%
  filter(year >= 2011) %>% # Sampel dengan observasi YoY lengkap
  arrange(country, year, quarter)

regional_asean <- panel_data$regional_asean %>%
  filter(year >= 2011) %>%
  arrange(year, quarter)

pdata <- pdata.frame(panel_final, index = c("country", "period"))

# ------------------------------------------------------------------------------
# 1. UJI PESARAN CD (CROSS-SECTIONAL DEPENDENCE)
# H0: Tidak ada cross-sectional dependence (lintas bagian independen)
# ------------------------------------------------------------------------------
cd_test_vars <- c("inflation_yoy", "gdp_growth", "money_growth", "reer_yoy", "hcpi_q", "reer_q")
cd_results_list <- list()

for (v in cd_test_vars) {
  form <- as.formula(paste(v, "~ 1"))
  test_res <- pcdtest(form, data = pdata, test = "cd")
  
  cd_results_list[[length(cd_results_list) + 1]] <- tibble(
    variable = v,
    test_name = "Pesaran CD (2004)",
    statistic = round(as.numeric(test_res$statistic), 4),
    p_value = as.numeric(test_res$p.value),
    conclusion = ifelse(test_res$p.value < 0.05, "Tolak H0: Terdapat Cross-Sectional Dependence Signifikan", "Gagal Tolak H0: Tidak Ada Bukti CD")
  )
}
cd_results_df <- bind_rows(cd_results_list)
cat("=== HASIL UJI PESARAN CD ===\n")
print(cd_results_df)

# ------------------------------------------------------------------------------
# 2. UJI PANEL UNIT ROOT (LEVIN-LIN-CHU & MADWALLA/FISHER-TYPE)
# ------------------------------------------------------------------------------
panel_vars <- c("inflation_yoy", "gdp_growth", "money_growth", "reer_yoy")
panel_ur_list <- list()

for (v in panel_vars) {
  # Bentuk matrix panel (T x N) untuk purtest
  pmat <- panel_final %>%
    select(country, period, all_of(v)) %>%
    pivot_wider(names_from = country, values_from = all_of(v)) %>%
    select(-period) %>%
    as.matrix()
  
  # Levin-Lin-Chu test
  tryCatch({
    llc <- purtest(pmat, test = "levinlin", exo = "intercept", lags = "AIC", pmax = 4)
    panel_ur_list[[length(panel_ur_list) + 1]] <- tibble(
      variable = v,
      test_type = "Levin-Lin-Chu Panel Unit Root",
      transformation = "Level / Growth Form",
      statistic = round(as.numeric(llc$statistic$statistic), 4),
      p_value = round(as.numeric(llc$statistic$p.value), 4),
      stationary = ifelse(llc$statistic$p.value < 0.05, "Stasioner I(0)", "Non-Stasioner I(1)")
    )
  }, error = function(e) {
    # Fallback jika matrix singularity
  })
  
  # Madwalla / Fisher-type test
  tryCatch({
    mad <- purtest(pmat, test = "madwu", exo = "intercept", lags = "AIC", pmax = 4)
    panel_ur_list[[length(panel_ur_list) + 1]] <- tibble(
      variable = v,
      test_type = "Fisher-type Panel ADF (Maddala-Wu)",
      transformation = "Level / Growth Form",
      statistic = round(as.numeric(mad$statistic$statistic), 4),
      p_value = round(as.numeric(mad$statistic$p.value), 4),
      stationary = ifelse(mad$statistic$p.value < 0.05, "Stasioner I(0)", "Non-Stasioner I(1)")
    )
  }, error = function(e) {})
}
panel_ur_df <- bind_rows(panel_ur_list)
cat("\n=== HASIL UJI PANEL UNIT ROOT ===\n")
print(panel_ur_df)

# ------------------------------------------------------------------------------
# 3. UJI UNIT ROOT DERET WAKTU REGIONAL & VARIABEL GLOBAL (ADF & KPSS)
# ------------------------------------------------------------------------------
ts_vars <- c("inflation_yoy", "gdp_growth", "money_growth", "reer_yoy", "fao_yoy", "ffr_change", "oil_yoy")
ts_ur_list <- list()

for (v in ts_vars) {
  s_vec <- regional_asean[[v]][!is.na(regional_asean[[v]])]
  
  # Level / Transformation Form
  adf_res <- adf.test(s_vec)
  kpss_res <- kpss.test(s_vec, null = "Level")
  
  # First Difference
  diff_vec <- diff(s_vec)
  adf_diff <- adf.test(diff_vec)
  
  ts_ur_list[[length(ts_ur_list) + 1]] <- tibble(
    variable = v,
    scope = ifelse(v %in% c("fao_yoy", "ffr_change", "oil_yoy"), "Global / External", "ASEAN Regional Aggregate"),
    adf_level_stat = round(as.numeric(adf_res$statistic), 3),
    adf_level_pval = round(as.numeric(adf_res$p.value), 4),
    kpss_level_stat = round(as.numeric(kpss_res$statistic), 3),
    kpss_level_pval = round(as.numeric(kpss_res$p.value), 4),
    adf_diff_stat = round(as.numeric(adf_diff$statistic), 3),
    adf_diff_pval = round(as.numeric(adf_diff$p.value), 4),
    integration_order = ifelse(adf_res$p.value < 0.05 || kpss_res$p.value > 0.05, "I(0) - Stasioner pada Bentuk Transformasi", "I(1) - Stasioner pada First Difference")
  )
}
ts_ur_df <- bind_rows(ts_ur_list)
cat("\n=== HASIL UJI UNIT ROOT REGIONAL & GLOBAL ===\n")
print(ts_ur_df)

# Simpan semua hasil stasioneritas
saveRDS(list(
  cd_test = cd_results_df,
  panel_unit_root = panel_ur_df,
  ts_unit_root = ts_ur_df
), "data/processed/stationarity_results.rds")

# Tulis gabungan ke CSV
stationarity_combined <- bind_rows(
  cd_results_df %>% mutate(category = "Cross-Sectional Dependence"),
  panel_ur_df %>% mutate(category = "Panel Unit Root"),
  ts_ur_df %>% mutate(category = "Time Series Unit Root")
)
write.csv(stationarity_combined, "output/ASEAN_Stationarity_Tests.csv", row.names = FALSE)

cat(">>> Selesai Tahap 7. Hasil stasioneritas tersimpan di output/ASEAN_Stationarity_Tests.csv\n")

