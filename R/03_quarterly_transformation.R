# ==============================================================================
# SCRIPT 03: QUARTERLY TRANSFORMATION
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
  library(zoo)
})

cat(">>> Memulai Tahap 3: Transformasi Data Menjadi Frekuensi Kuartalan...\n")

clean_tables <- readRDS("data/processed/clean_raw_tables.rds")

# ------------------------------------------------------------------------------
# 1. HCPI MENJADI INFLASI KUARTALAN
# ------------------------------------------------------------------------------
hcpi_m <- clean_tables$hcpi_monthly

# Agregasi 3 bulan per kuartal
hcpi_q_df <- hcpi_m %>%
  group_by(country, year, quarter, period) %>%
  summarise(
    valid_months = sum(!is.na(hcpi)),
    hcpi_q = if_else(valid_months >= 2, mean(hcpi, na.rm = TRUE), NA_real_),
    .groups = "drop"
  ) %>%
  arrange(country, year, quarter)

# Hitung inflasi YoY dan QoQ per negara
# Catatan penting: inflation_yoy = 100 * (hcpi_q / lag(hcpi_q, 4) - 1)
# 4 kuartal pertama secara alami NA karena tidak memiliki lag pembanding tahun sebelumnya
hcpi_q_df <- hcpi_q_df %>%
  group_by(country) %>%
  mutate(
    hcpi_lag1 = lag(hcpi_q, 1),
    hcpi_lag4 = lag(hcpi_q, 4),
    inflation_qoq = 100 * (hcpi_q / hcpi_lag1 - 1),
    inflation_yoy = 100 * (hcpi_q / hcpi_lag4 - 1)
  ) %>%
  ungroup()

cat("Transformasi HCPI selesai. Total observasi kuartalan:", nrow(hcpi_q_df), "\n")
cat("Periode kuartal HCPI:", min(hcpi_q_df$period), "s.d.", max(hcpi_q_df$period), "\n")

# ------------------------------------------------------------------------------
# 2. REER MENJADI KUARTALAN
# ------------------------------------------------------------------------------
reer_m <- clean_tables$reer_monthly

reer_q_df <- reer_m %>%
  group_by(country, year, quarter, period) %>%
  summarise(
    valid_months = sum(!is.na(reer)),
    reer_q = if_else(valid_months >= 2, mean(reer, na.rm = TRUE), NA_real_),
    .groups = "drop"
  ) %>%
  arrange(country, year, quarter) %>%
  group_by(country) %>%
  mutate(
    reer_lag4 = lag(reer_q, 4),
    reer_yoy = 100 * (reer_q / reer_lag4 - 1)
  ) %>%
  ungroup()

cat("Transformasi REER selesai. Total observasi kuartalan:", nrow(reer_q_df), "\n")

# ------------------------------------------------------------------------------
# 3. VARIABEL GLOBAL (FAO, FFR, OIL) MENJADI KUARTALAN
# ------------------------------------------------------------------------------
# FAO Food Price Index
fao_q_df <- clean_tables$fao_monthly %>%
  group_by(year, quarter, period) %>%
  summarise(
    fao_q = mean(fao_index, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(year, quarter) %>%
  mutate(
    fao_lag4 = lag(fao_q, 4),
    fao_yoy = 100 * (fao_q / fao_lag4 - 1)
  )

# Federal Funds Rate
ffr_q_df <- clean_tables$ffr_monthly %>%
  group_by(year, quarter, period) %>%
  summarise(
    ffr_q = mean(ffr, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(year, quarter) %>%
  mutate(
    ffr_lag1 = lag(ffr_q, 1),
    ffr_change = ffr_q - ffr_lag1
  )

# Crude Oil Price
oil_q_df <- clean_tables$oil_monthly %>%
  group_by(year, quarter, period) %>%
  summarise(
    oil_q = mean(oil_price, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(year, quarter) %>%
  mutate(
    oil_lag4 = lag(oil_q, 4),
    oil_yoy = 100 * (oil_q / oil_lag4 - 1)
  )

cat("Transformasi variabel global selesai (FAO, FFR, Oil).\n")

# ------------------------------------------------------------------------------
# 4. TEMPORAL DISAGGREGATION UNTUK PDB DAN MONEY GROWTH
# Algoritma Denton-Cholette Quadratic Smoothing tanpa indikator eksternal
# Formula: min sum (Delta y_q)^2 subject to mean(y_{t, 1:4}) = Y_t
# ------------------------------------------------------------------------------
denton_disagg <- function(annual_vec) {
  # annual_vec: numeric vector of annual growth rates
  # Returns: vector of length 4 * length(annual_vec) where mean of each 4 qtr = annual_vec
  n_years <- length(annual_vec)
  if (n_years == 0) return(numeric(0))
  if (n_years == 1) return(rep(annual_vec, 4))
  
  n_qtrs <- n_years * 4
  
  # Matriks agregasi B (n_years x n_qtrs)
  B <- matrix(0, nrow = n_years, ncol = n_qtrs)
  for (t in 1:n_years) {
    B[t, ((t-1)*4 + 1):(t*4)] <- 0.25
  }
  
  # Matriks differensiasi pertama D ((n_qtrs - 1) x n_qtrs)
  D <- matrix(0, nrow = n_qtrs - 1, ncol = n_qtrs)
  for (k in 1:(n_qtrs - 1)) {
    D[k, k] <- -1
    D[k, k+1] <- 1
  }
  
  # Penalti kuadratik regularisasi
  A <- t(D) %*% D + diag(1e-6, n_qtrs)
  A_inv <- solve(A)
  
  # Penyelesaian Lagrange Multiplier
  M <- B %*% A_inv %*% t(B)
  lambda <- solve(M, annual_vec)
  y <- A_inv %*% t(B) %*% lambda
  
  return(as.vector(y))
}

# A. Disaggregation PDB
pdb_annual <- clean_tables$gdp_annual %>% arrange(country, year)
unique_countries <- unique(pdb_annual$country)

pdb_q_list <- list()
disagg_audit_list <- list()

for (cntry in unique_countries) {
  sub_pdb <- pdb_annual %>% filter(country == cntry) %>% arrange(year)
  ann_vals <- sub_pdb$gdp_growth
  years <- sub_pdb$year
  
  # PDB lengkap 2010-2025
  q_vals <- denton_disagg(ann_vals)
  
  # Bentuk dataframe kuartalan
  q_df <- tibble(
    country = cntry,
    year = rep(years, each = 4),
    quarter = rep(1:4, times = length(years)),
    period = sprintf("%d Q%d", rep(years, each = 4), rep(1:4, times = length(years))),
    gdp_growth = q_vals
  )
  pdb_q_list[[cntry]] <- q_df
  
  # Audit disaggregation
  q_mat <- matrix(q_vals, ncol = 4, byrow = TRUE)
  q_means <- rowMeans(q_mat)
  for (i in seq_along(years)) {
    disagg_audit_list[[length(disagg_audit_list) + 1]] <- tibble(
      country = cntry,
      variable = "GDP_Growth",
      year = years[i],
      annual_benchmark = ann_vals[i],
      q1 = q_mat[i, 1],
      q2 = q_mat[i, 2],
      q3 = q_mat[i, 3],
      q4 = q_mat[i, 4],
      quarterly_mean = q_means[i],
      discrepancy = q_means[i] - ann_vals[i],
      method = "Denton-Cholette First-Difference Minimization",
      temporal_constraint = "mean(Q1..Q4) == Annual_Growth"
    )
  }
}
pdb_q_df <- bind_rows(pdb_q_list)

# B. Disaggregation Money Growth
mg_annual <- clean_tables$money_annual %>% arrange(country, year)

mg_q_list <- list()

for (cntry in unique_countries) {
  sub_mg <- mg_annual %>% filter(country == cntry) %>% arrange(year)
  years <- sub_mg$year
  ann_vals <- sub_mg$money_growth
  
  # Identifikasi contiguous segment yang tidak NA
  valid_idx <- which(!is.na(ann_vals))
  
  q_vals <- rep(NA_real_, length(years) * 4)
  
  if (length(valid_idx) > 0) {
    valid_ann <- ann_vals[valid_idx]
    valid_q <- denton_disagg(valid_ann)
    
    # Masukkan ke posisi kuartal yang sesuai
    for (vi in seq_along(valid_idx)) {
      y_idx <- valid_idx[vi]
      q_pos <- ((y_idx - 1) * 4 + 1):(y_idx * 4)
      src_pos <- ((vi - 1) * 4 + 1):(vi * 4)
      q_vals[q_pos] <- valid_q[src_pos]
      
      # Audit disaggregation
      disagg_audit_list[[length(disagg_audit_list) + 1]] <- tibble(
        country = cntry,
        variable = "Money_Growth",
        year = years[y_idx],
        annual_benchmark = ann_vals[y_idx],
        q1 = valid_q[src_pos[1]],
        q2 = valid_q[src_pos[2]],
        q3 = valid_q[src_pos[3]],
        q4 = valid_q[src_pos[4]],
        quarterly_mean = mean(valid_q[src_pos]),
        discrepancy = mean(valid_q[src_pos]) - ann_vals[y_idx],
        method = "Denton-Cholette First-Difference Minimization",
        temporal_constraint = "mean(Q1..Q4) == Annual_Growth"
      )
    }
  }
  
  q_df <- tibble(
    country = cntry,
    year = rep(years, each = 4),
    quarter = rep(1:4, times = length(years)),
    period = sprintf("%d Q%d", rep(years, each = 4), rep(1:4, times = length(years))),
    money_growth = q_vals
  )
  mg_q_list[[cntry]] <- q_df
}
mg_q_df <- bind_rows(mg_q_list)

disagg_audit_df <- bind_rows(disagg_audit_list)

cat("Temporal disaggregation selesai. Total baris audit disaggregation:", nrow(disagg_audit_df), "\n")
cat("Maksimum deviasi dari benchmark tahunan:", max(abs(disagg_audit_df$discrepancy)), "\n")

# Simpan hasil kuartalan unimputed
dir.create("output", showWarnings = FALSE)
write.csv(disagg_audit_df, "output/ASEAN_Disaggregation_Audit.csv", row.names = FALSE)

saveRDS(list(
  hcpi_q = hcpi_q_df,
  reer_q = reer_q_df,
  fao_q = fao_q_df,
  ffr_q = ffr_q_df,
  oil_q = oil_q_df,
  pdb_q = pdb_q_df,
  mg_q = mg_q_df,
  disagg_audit = disagg_audit_df
), "data/processed/quarterly_unimputed.rds")

cat(">>> Selesai Tahap 3. File tersimpan di data/processed/quarterly_unimputed.rds dan output/ASEAN_Disaggregation_Audit.csv\n")

