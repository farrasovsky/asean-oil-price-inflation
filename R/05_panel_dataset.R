# ==============================================================================
# SCRIPT 05: PANEL DATASET GENERATION
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

cat(">>> Memulai Tahap 5: Pembentukan Dataset Panel dan Agregat Regional...\n")

imp_data <- readRDS("data/processed/quarterly_imputed.rds")
unimp_data <- readRDS("data/processed/quarterly_unimputed.rds")

# Daftar periode acuan panel: 2010 Q1 s.d. 2025 Q1 (61 kuartal, sesuai rentang HCPI)
# 10 negara x 61 kuartal = 610 baris observasi panel
quarters_grid <- expand_grid(
  country = sort(unique(imp_data$hcpi_final$country)),
  year = 2010:2025,
  quarter = 1:4
) %>%
  filter(!(year == 2025 & quarter > 1)) %>%
  mutate(period = sprintf("%d Q%d", year, quarter)) %>%
  arrange(country, year, quarter)

# ------------------------------------------------------------------------------
# 1. BENTUK PANEL RAW (UNIMPUTED / DATA ASLI DENGAN MISSING ALAMI)
# ------------------------------------------------------------------------------
panel_raw <- quarters_grid %>%
  left_join(unimp_data$hcpi_q %>% select(country, year, quarter, hcpi_q, inflation_qoq, inflation_yoy), by = c("country", "year", "quarter")) %>%
  left_join(unimp_data$pdb_q %>% select(country, year, quarter, gdp_growth), by = c("country", "year", "quarter")) %>%
  left_join(unimp_data$mg_q %>% select(country, year, quarter, money_growth), by = c("country", "year", "quarter")) %>%
  left_join(unimp_data$reer_q %>% select(country, year, quarter, reer_q, reer_yoy), by = c("country", "year", "quarter")) %>%
  left_join(unimp_data$fao_q %>% select(year, quarter, fao_q, fao_yoy), by = c("year", "quarter")) %>%
  left_join(unimp_data$ffr_q %>% select(year, quarter, ffr_q, ffr_change), by = c("year", "quarter")) %>%
  left_join(unimp_data$oil_q %>% select(year, quarter, oil_q, oil_yoy), by = c("year", "quarter"))

# ------------------------------------------------------------------------------
# 2. BENTUK PANEL FINAL (TERIMPUTASI SECARA TRANSPARAN & DILENGKAPI FLAG KUALITAS)
# ------------------------------------------------------------------------------
panel_final <- quarters_grid %>%
  left_join(imp_data$hcpi_final %>% select(country, year, quarter, hcpi_q = hcpi_q_imp, inflation_qoq = inflation_qoq_imp, inflation_yoy = inflation_yoy_imp), by = c("country", "year", "quarter")) %>%
  left_join(imp_data$pdb_final %>% select(country, year, quarter, gdp_growth), by = c("country", "year", "quarter")) %>%
  left_join(imp_data$mg_final %>% select(country, year, quarter, money_growth = money_growth_imp), by = c("country", "year", "quarter")) %>%
  left_join(imp_data$reer_final %>% select(country, year, quarter, reer_q = reer_q_imp, reer_yoy = reer_yoy_imp), by = c("country", "year", "quarter")) %>%
  left_join(imp_data$fao_final %>% select(year, quarter, fao_q, fao_yoy), by = c("year", "quarter")) %>%
  left_join(imp_data$ffr_final %>% select(year, quarter, ffr_q, ffr_change), by = c("year", "quarter")) %>%
  left_join(imp_data$oil_final %>% select(year, quarter, oil_q, oil_yoy), by = c("year", "quarter"))

# Tentukan imputation_count dan data_quality_flag untuk setiap baris panel_final
audit_df <- imp_data$imputation_audit

panel_final <- panel_final %>%
  rowwise() %>%
  mutate(
    # Hitung berapa variabel pada baris ini yang berasal dari imputasi
    imputations_in_row = sum(
      (audit_df$country == country & audit_df$period == period & audit_df$variable %in% c("hcpi_q", "money_growth", "reer_q"))
    ),
    data_quality_flag = case_when(
      imputations_in_row == 0 & year >= 2011 ~ "High_Quality_Observed",
      imputations_in_row == 0 & year == 2010 ~ "Baseline_Lag_Origin",
      imputations_in_row == 1 ~ "Minor_Imputation_1Var",
      imputations_in_row >= 2 ~ "Major_Imputation_MultiVar",
      TRUE ~ "Standard"
    )
  ) %>%
  ungroup() %>%
  rename(imputation_count = imputations_in_row)

# Pastikan susunan kolom sesuai standar master prompt
cols_order <- c(
  "country", "year", "quarter", "period",
  "hcpi_q", "inflation_yoy", "inflation_qoq",
  "gdp_growth", "money_growth",
  "reer_q", "reer_yoy",
  "fao_q", "fao_yoy",
  "ffr_q", "ffr_change",
  "oil_q", "oil_yoy",
  "imputation_count", "data_quality_flag"
)
panel_final <- panel_final %>% select(all_of(cols_order))
panel_raw   <- panel_raw %>% select(any_of(cols_order))

# ------------------------------------------------------------------------------
# 3. BENTUK REGIONAL AGGREGATE ASEAN (EQUAL-WEIGHTED MACRO REGION)
# Variabel global hanya muncul 1 observasi per kuartal
# ------------------------------------------------------------------------------
regional_asean <- panel_final %>%
  group_by(year, quarter, period) %>%
  summarise(
    hcpi_q = mean(hcpi_q, na.rm = TRUE),
    inflation_yoy = mean(inflation_yoy, na.rm = TRUE),
    inflation_qoq = mean(inflation_qoq, na.rm = TRUE),
    gdp_growth = mean(gdp_growth, na.rm = TRUE),
    money_growth = mean(money_growth, na.rm = TRUE),
    reer_q = mean(reer_q, na.rm = TRUE),
    reer_yoy = mean(reer_yoy, na.rm = TRUE),
    fao_q = first(fao_q),
    fao_yoy = first(fao_yoy),
    ffr_q = first(ffr_q),
    ffr_change = first(ffr_change),
    oil_q = first(oil_q),
    oil_yoy = first(oil_yoy),
    total_countries = n(),
    avg_imputation_count = mean(imputation_count),
    .groups = "drop"
  ) %>%
  arrange(year, quarter)

# ------------------------------------------------------------------------------
# 4. SIMPAN DATASET
# ------------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
write.csv(panel_final, "output/ASEAN_Inflation_Quarterly_Final.csv", row.names = FALSE)
write.csv(panel_raw, "output/ASEAN_Inflation_Quarterly_Raw.csv", row.names = FALSE)
write.csv(regional_asean, "output/ASEAN_Regional_Quarterly.csv", row.names = FALSE)

saveRDS(list(
  panel_final = panel_final,
  panel_raw = panel_raw,
  regional_asean = regional_asean
), "data/processed/panel_final.rds")

cat("=== RINGKASAN DATASET PANEL FINAL ===\n")
cat("1. Total Baris Panel Final:", nrow(panel_final), "(10 Negara x 61 Kuartal)\n")
cat("2. Rentang Periode:", min(panel_final$period), "s.d.", max(panel_final$period), "\n")
cat("3. Kolom Panel Final:\n  ", paste(names(panel_final), collapse = ", "), "\n")
cat("4. Distribusi Kualitas Data:\n")
print(table(panel_final$data_quality_flag))
cat("5. File tersimpan di: output/ASEAN_Inflation_Quarterly_Final.csv\n")
cat(">>> Selesai Tahap 5.\n")

