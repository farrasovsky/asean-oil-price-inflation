# ==============================================================================
# SCRIPT 01: AUDIT DATA SUMBER
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

cat(">>> Memulai Tahap 1: Audit Data Sumber...\n")

raw_file <- "data/raw/Kebutuhan Data per Variabel Fix (1).xlsx"
if (!file.exists(raw_file)) {
  stop("File sumber tidak ditemukan di: ", raw_file)
}

sheets <- excel_sheets(raw_file)
cat("Sheets terdeteksi (", length(sheets), "):\n", paste("-", sheets, collapse = "\n"), "\n\n")

audit_summary <- list()
sheet_details <- list()

# 1. Audit per sheet
for (s in sheets) {
  df_raw <- read_excel(raw_file, sheet = s, col_names = FALSE)
  nr <- nrow(df_raw)
  nc <- ncol(df_raw)
  
  # Basic properties
  prop <- tibble(
    sheet_name = s,
    total_rows = nr,
    total_cols = nc,
    header_row_sample = paste(head(as.character(df_raw[1, ]), 5), collapse = " | "),
    row2_sample = paste(head(as.character(df_raw[2, ]), 5), collapse = " | ")
  )
  sheet_details[[s]] <- prop
}

sheet_overview_df <- bind_rows(sheet_details)

# 2. Detailed audit of Inflasi
inf_raw <- read_excel(raw_file, sheet = "Inflasi Cleaned (kurang", col_names = FALSE)
inf_countries <- as.character(unlist(inf_raw[3:nrow(inf_raw), 1]))
inf_dates_raw <- as.character(unlist(inf_raw[2, 2:ncol(inf_raw)]))
inf_vals <- inf_raw[3:nrow(inf_raw), 2:ncol(inf_raw)]

inf_audit_df <- tibble(
  country = inf_countries,
  variable = "HCPI",
  source_sheet = "Inflasi Cleaned (kurang",
  start_period = inf_dates_raw[1],
  end_period_recorded = tail(inf_dates_raw[!is.na(inf_dates_raw)], 1),
  total_periods = ncol(inf_vals),
  missing_count = apply(inf_vals, 1, function(x) sum(is.na(x))),
  missing_pct = round(apply(inf_vals, 1, function(x) sum(is.na(x))) / ncol(inf_vals) * 100, 2),
  notes = ifelse(country == "Myanmar", "Banyak periode akhir kosong",
          ifelse(country %in% c("Thailand", "Cambodia", "Singapore"), "Beberapa bulan di akhir sampel belum terisi", "Lengkap/Hampir lengkap"))
)

# 3. Detailed audit of PDB
pdb_raw <- read_excel(raw_file, sheet = "PDB")
pdb_countries <- pdb_raw$Negara
pdb_years <- setdiff(names(pdb_raw), "Negara")
pdb_vals <- pdb_raw[, pdb_years]

pdb_audit_df <- tibble(
  country = pdb_countries,
  variable = "GDP_Growth",
  source_sheet = "PDB",
  start_period = min(pdb_years),
  end_period = max(pdb_years),
  total_periods = length(pdb_years),
  missing_count = rowSums(is.na(pdb_vals)),
  missing_pct = round(rowSums(is.na(pdb_vals)) / length(pdb_years) * 100, 2),
  notes = "Data tahunan lengkap tanpa missing"
)

# 4. Detailed audit of Money Growth
mg_raw <- read_excel(raw_file, sheet = "Money Growth (kurang)")
mg_countries <- mg_raw$Negara
mg_years <- setdiff(names(mg_raw), "Negara")
mg_vals <- mg_raw[, mg_years]

mg_audit_df <- tibble(
  country = mg_countries,
  variable = "Money_Growth",
  source_sheet = "Money Growth (kurang)",
  start_period = min(mg_years),
  end_period = max(mg_years),
  total_periods = length(mg_years),
  missing_count = rowSums(is.na(mg_vals)),
  missing_pct = round(rowSums(is.na(mg_vals)) / length(mg_years) * 100, 2),
  notes = ifelse(country == "Laos (Lao PDR)", "Hanya tersedia tahun 2010",
          ifelse(country %in% c("Singapore", "Myanmar"), "Tersedia s.d. 2020",
          ifelse(country %in% c("Vietnam", "Cambodia", "Philipines"), "Tersedia s.d. 2022", "Lengkap 2010-2025")))
)

# 5. Detailed audit of REER
reer_raw <- read_excel(raw_file, sheet = "REER Cleaned (kurang)")
reer_countries <- setdiff(names(reer_raw), "Month")
reer_months <- reer_raw$Month
reer_audit_df <- tibble(
  country = reer_countries,
  variable = "REER",
  source_sheet = "REER Cleaned (kurang)",
  start_period = min(reer_months),
  end_period = max(reer_months),
  total_periods = length(reer_months),
  missing_count = sapply(reer_raw[, reer_countries], function(col) sum(is.na(col))),
  missing_pct = round(sapply(reer_raw[, reer_countries], function(col) sum(is.na(col))) / length(reer_months) * 100, 2),
  notes = ifelse(reer_countries == "Myanmar", "27 observasi awal (2010M01-2012M03) kosong sebelum float", "Lengkap 192 bulan")
)

# 6. Detailed audit of Global variables (FAO, FFR, Oil)
fao_raw <- read_excel(raw_file, sheet = "FAO Cleaned")
ffr_raw <- read_excel(raw_file, sheet = "Federal Funds Rate Cleaned")
oil_raw <- read_excel(raw_file, sheet = "Oil")

global_audit_df <- tibble(
  variable = c("FAO_Food_Price_Index", "Federal_Funds_Rate", "Crude_Oil_Price"),
  source_sheet = c("FAO Cleaned", "Federal Funds Rate Cleaned", "Oil"),
  frequency = "Bulanan",
  start_period = c(format(min(fao_raw[[1]])), format(min(ffr_raw[[1]])), format(min(oil_raw[[1]]))),
  end_period = c(format(max(fao_raw[[1]])), format(max(ffr_raw[[1]])), format(max(oil_raw[[1]]))),
  total_periods = c(nrow(fao_raw), nrow(ffr_raw), nrow(oil_raw)),
  missing_count = c(sum(is.na(fao_raw[[2]])), sum(is.na(ffr_raw[[2]])), sum(is.na(oil_raw[[2]]))),
  missing_pct = c(0, 0, 0),
  notes = "Variabel global/common shocks, lengkap tanpa missing values"
)

# 7. Comprehensive country-level audit table
all_country_audit <- bind_rows(
  inf_audit_df,
  pdb_audit_df,
  mg_audit_df,
  reer_audit_df
)

# Simpan hasil audit ke CSV
dir.create("output", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)

write.csv(sheet_overview_df, "output/Audit_Sheet_Overview.csv", row.names = FALSE)
write.csv(all_country_audit, "output/Data_Audit.csv", row.names = FALSE)
write.csv(global_audit_df, "output/Audit_Global_Variables.csv", row.names = FALSE)

saveRDS(list(
  sheet_overview = sheet_overview_df,
  country_audit = all_country_audit,
  global_audit = global_audit_df,
  inf_audit = inf_audit_df,
  pdb_audit = pdb_audit_df,
  mg_audit = mg_audit_df,
  reer_audit = reer_audit_df
), "data/processed/audit_results.rds")

cat("=== RINGKASAN AUDIT DATA SUMBER ===\n")
cat("1. Total sheet:", length(sheets), "\n")
cat("2. Negara terdeteksi:", paste(unique(all_country_audit$country), collapse = ", "), "\n")
cat("3. Variabel makro domestik: HCPI (bulanan), PDB (tahunan), Money Growth (tahunan), REER (bulanan)\n")
cat("4. Variabel makro global: FAO Food Index (bulanan), FFR (bulanan), Oil Price (bulanan)\n")
cat("5. File tersimpan di: output/Data_Audit.csv\n")
cat(">>> Selesai Tahap 1.\n")

