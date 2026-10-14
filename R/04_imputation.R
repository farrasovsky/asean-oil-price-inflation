# ==============================================================================
# SCRIPT 04: IMPUTATION & QUALITY AUDIT
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(zoo)
})

cat(">>> Memulai Tahap 4: Penanganan Missing Values dan Audit Imputasi...\n")

unimputed_data <- readRDS("data/processed/quarterly_unimputed.rds")

hcpi_q <- unimputed_data$hcpi_q
reer_q <- unimputed_data$reer_q
pdb_q  <- unimputed_data$pdb_q
mg_q   <- unimputed_data$mg_q
fao_q  <- unimputed_data$fao_q
ffr_q  <- unimputed_data$ffr_q
oil_q  <- unimputed_data$oil_q

imputation_records <- list()

# ------------------------------------------------------------------------------
# 1. IMPUTASI HCPI (KUARTALAN)
# ------------------------------------------------------------------------------
hcpi_imputed_list <- list()

for (cntry in unique(hcpi_q$country)) {
  sub_df <- hcpi_q %>% filter(country == cntry) %>% arrange(year, quarter)
  vals <- sub_df$hcpi_q
  n <- length(vals)
  
  is_na_idx <- which(is.na(vals))
  
  if (length(is_na_idx) > 0) {
    # Ekstrapolasi trailing growth untuk tail missing
    # Hitung rata-rata pertumbuhan kuartalan dari 4 kuartal valid terakhir
    last_valid <- max(which(!is.na(vals)))
    growth_rate <- if (last_valid >= 5) {
      mean(vals[(last_valid-3):last_valid] / vals[(last_valid-4):(last_valid-1)] - 1, na.rm = TRUE)
    } else {
      0.005 # fallback 0.5% per kuartal
    }
    
    vals_imp <- vals
    for (idx in is_na_idx) {
      if (idx > last_valid) {
        steps <- idx - last_valid
        vals_imp[idx] <- vals[last_valid] * ((1 + growth_rate) ^ steps)
        
        imputation_records[[length(imputation_records) + 1]] <- tibble(
          country = cntry,
          variable = "hcpi_q",
          period = sub_df$period[idx],
          year = sub_df$year[idx],
          quarter = sub_df$quarter[idx],
          original_value = NA_real_,
          imputed_value = round(vals_imp[idx], 4),
          imputation_method = "Trailing Geometric Growth Extrapolation",
          missing_type = "tail_missing",
          is_imputed = TRUE,
          is_extrapolated = TRUE,
          reason = "Data bulanan HCPI di akhir sampel belum dilaporkan",
          source_sheet = "Inflasi Cleaned (kurang"
        )
      } else {
        # Internal missing (interpolasi linear jika ada)
        vals_imp[idx] <- na.approx(vals, rule = 2)[idx]
        imputation_records[[length(imputation_records) + 1]] <- tibble(
          country = cntry,
          variable = "hcpi_q",
          period = sub_df$period[idx],
          year = sub_df$year[idx],
          quarter = sub_df$quarter[idx],
          original_value = NA_real_,
          imputed_value = round(vals_imp[idx], 4),
          imputation_method = "Linear Interpolation",
          missing_type = "internal_missing",
          is_imputed = TRUE,
          is_extrapolated = FALSE,
          reason = "Missing internal terisolasi",
          source_sheet = "Inflasi Cleaned (kurang"
        )
      }
    }
    sub_df$hcpi_q_imp <- vals_imp
  } else {
    sub_df$hcpi_q_imp <- vals
  }
  
  # Hitung ulang inflasi YoY dan QoQ dari seri HCPI terimputasi
  sub_df <- sub_df %>%
    mutate(
      hcpi_lag1_imp = lag(hcpi_q_imp, 1),
      hcpi_lag4_imp = lag(hcpi_q_imp, 4),
      inflation_qoq_imp = 100 * (hcpi_q_imp / hcpi_lag1_imp - 1),
      inflation_yoy_imp = 100 * (hcpi_q_imp / hcpi_lag4_imp - 1)
    )
  
  # Catat imputasi inflasi YoY untuk kuartal yang terimputasi (kuartal 1-4 tetap NA alami)
  for (idx in seq_len(nrow(sub_df))) {
    if (idx > 4 && is.na(sub_df$inflation_yoy[idx]) && !is.na(sub_df$inflation_yoy_imp[idx])) {
      imputation_records[[length(imputation_records) + 1]] <- tibble(
        country = cntry,
        variable = "inflation_yoy",
        period = sub_df$period[idx],
        year = sub_df$year[idx],
        quarter = sub_df$quarter[idx],
        original_value = NA_real_,
        imputed_value = round(sub_df$inflation_yoy_imp[idx], 4),
        imputation_method = "Derived from Imputed HCPI",
        missing_type = "tail_missing",
        is_imputed = TRUE,
        is_extrapolated = TRUE,
        reason = "Ditranslasikan dari indeks harga HCPI terimputasi",
        source_sheet = "Inflasi Cleaned (kurang"
      )
    }
  }
  
  hcpi_imputed_list[[cntry]] <- sub_df
}
hcpi_q_final <- bind_rows(hcpi_imputed_list)

# ------------------------------------------------------------------------------
# 2. IMPUTASI REER (KUARTALAN)
# ------------------------------------------------------------------------------
reer_imputed_list <- list()

for (cntry in unique(reer_q$country)) {
  sub_df <- reer_q %>% filter(country == cntry) %>% arrange(year, quarter)
  vals <- sub_df$reer_q
  is_na_idx <- which(is.na(vals))
  
  if (length(is_na_idx) > 0) {
    # Myanmar memiliki 9 kuartal awal (2010 Q1 - 2012 Q1) kosong sebelum unifikasi kurs 2012
    # Gunakan backward constant fallback / first observed value
    first_valid <- min(which(!is.na(vals)))
    vals_imp <- na.locf(vals, fromLast = TRUE)
    
    for (idx in is_na_idx) {
      imputation_records[[length(imputation_records) + 1]] <- tibble(
        country = cntry,
        variable = "reer_q",
        period = sub_df$period[idx],
        year = sub_df$year[idx],
        quarter = sub_df$quarter[idx],
        original_value = NA_real_,
        imputed_value = round(vals_imp[idx], 4),
        imputation_method = "Backward Constant Fallback (Earliest Observed)",
        missing_type = "head_missing",
        is_imputed = TRUE,
        is_extrapolated = TRUE,
        reason = "Myanmar menerapkan multiple exchange rate sebelum April 2012",
        source_sheet = "REER Cleaned (kurang)"
      )
    }
    sub_df$reer_q_imp <- vals_imp
  } else {
    sub_df$reer_q_imp <- vals
  }
  
  sub_df <- sub_df %>%
    mutate(
      reer_lag4_imp = lag(reer_q_imp, 4),
      reer_yoy_imp = 100 * (reer_q_imp / reer_lag4_imp - 1)
    )
  
  reer_imputed_list[[cntry]] <- sub_df
}
reer_q_final <- bind_rows(reer_imputed_list)

# ------------------------------------------------------------------------------
# 3. IMPUTASI MONEY GROWTH (KUARTALAN)
# ------------------------------------------------------------------------------
mg_imputed_list <- list()

for (cntry in unique(mg_q$country)) {
  sub_df <- mg_q %>% filter(country == cntry) %>% arrange(year, quarter)
  vals <- sub_df$money_growth
  is_na_idx <- which(is.na(vals))
  
  if (length(is_na_idx) > 0) {
    valid_idx <- which(!is.na(vals))
    vals_imp <- vals
    
    if (length(valid_idx) == 4) {
      # Laos: Hanya 4 kuartal (2010 Q1-Q4) yang tersedia
      # Gunakan mean historical / decaying fallback
      fallback_val <- mean(vals[valid_idx], na.rm = TRUE)
      for (idx in is_na_idx) {
        vals_imp[idx] <- fallback_val
        imputation_records[[length(imputation_records) + 1]] <- tibble(
          country = cntry,
          variable = "money_growth",
          period = sub_df$period[idx],
          year = sub_df$year[idx],
          quarter = sub_df$quarter[idx],
          original_value = NA_real_,
          imputed_value = round(fallback_val, 4),
          imputation_method = "Constant Fallback (Historical Mean)",
          missing_type = "extended_tail_missing",
          is_imputed = TRUE,
          is_extrapolated = TRUE,
          reason = "Hanya tahun 2010 tersedia di sumber untuk Laos",
          source_sheet = "Money Growth (kurang)"
        )
      }
    } else {
      # Negara lain (Cambodia, Philippines, Vietnam, Singapore, Myanmar)
      # Gunakan moving average dari 8 kuartal terakhir yang valid
      last_valid <- max(valid_idx)
      trailing_mean <- mean(vals[(last_valid-7):last_valid], na.rm = TRUE)
      
      for (idx in is_na_idx) {
        vals_imp[idx] <- trailing_mean
        imputation_records[[length(imputation_records) + 1]] <- tibble(
          country = cntry,
          variable = "money_growth",
          period = sub_df$period[idx],
          year = sub_df$year[idx],
          quarter = sub_df$quarter[idx],
          original_value = NA_real_,
          imputed_value = round(trailing_mean, 4),
          imputation_method = "Trailing 8-Quarter Moving Average Extrapolation",
          missing_type = "tail_missing",
          is_imputed = TRUE,
          is_extrapolated = TRUE,
          reason = "Data Money Growth tahun akhir belum tersedia di sumber",
          source_sheet = "Money Growth (kurang)"
        )
      }
    }
    sub_df$money_growth_imp <- vals_imp
  } else {
    sub_df$money_growth_imp <- vals
  }
  
  mg_imputed_list[[cntry]] <- sub_df
}
mg_q_final <- bind_rows(mg_imputed_list)

# ------------------------------------------------------------------------------
# 4. GABUNGKAN AUDIT IMPUTASI
# ------------------------------------------------------------------------------
imputation_audit_df <- bind_rows(imputation_records)

cat("Total observasi diimputasi:", nrow(imputation_audit_df), "\n")
print(imputation_audit_df %>% count(variable, imputation_method))

write.csv(imputation_audit_df, "output/ASEAN_Imputation_Audit.csv", row.names = FALSE)

saveRDS(list(
  hcpi_final = hcpi_q_final,
  reer_final = reer_q_final,
  pdb_final  = pdb_q, # PDB lengkap 100% tanpa missing
  mg_final   = mg_q_final,
  fao_final  = fao_q,
  ffr_final  = ffr_q,
  oil_final  = oil_q,
  imputation_audit = imputation_audit_df
), "data/processed/quarterly_imputed.rds")

cat(">>> Selesai Tahap 4. File audit tersimpan di output/ASEAN_Imputation_Audit.csv\n")

