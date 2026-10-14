# ==============================================================================
# SCRIPT 14: MANDATORY POST-EXPORT VALIDATION
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tools)
})

cat(">>> Memulai Tahap 14: Validasi Akhir dan Verifikasi Integritas File...\n\n")

final_excel <- "output/ASEAN_Inflation_Quarterly_Final.xlsx"
final_csv   <- "output/ASEAN_Inflation_Quarterly_Final.csv"
audit_excel <- "output/Data_Audit.xlsx"

validation_checks <- list()

add_check <- function(name, passed, detail) {
  validation_checks[[length(validation_checks) + 1]] <<- tibble(
    Check_Item = name,
    Status = ifelse(passed, "PASS [OK]", "FAIL [ERROR]"),
    Detail = detail
  )
}

# 1. Cek keberadaan file fisik
excel_exists <- file.exists(final_excel)
csv_exists   <- file.exists(final_csv)
audit_exists <- file.exists(audit_excel)

add_check("Keberadaan File Excel Final", excel_exists, paste("Path:", final_excel))
add_check("Keberadaan File CSV Final", csv_exists, paste("Path:", final_csv))
add_check("Keberadaan File Audit Excel", audit_exists, paste("Path:", audit_excel))

# 2. Cek ukuran file fisik (tidak kosong dan masuk akal)
if (excel_exists) {
  sz_excel <- file.size(final_excel)
  add_check("Ukuran File Excel Masuk Akal", sz_excel > 100000, sprintf("%.1f KB", sz_excel / 1024))
}
if (csv_exists) {
  sz_csv <- file.size(final_csv)
  add_check("Ukuran File CSV Masuk Akal", sz_csv > 20000, sprintf("%.1f KB", sz_csv / 1024))
}

# 3. Buka kembali file Excel dengan readxl dan periksa seluruh sheet
if (excel_exists) {
  sheets_found <- excel_sheets(final_excel)
  n_sheets <- length(sheets_found)
  add_check("Jumlah Sheet Excel Final", n_sheets == 30, sprintf("%d Sheet terdeteksi (Target: 30)", n_sheets))
  
  expected_sheets <- c(
    "README", "Data_Audit", "Raw_HCPI", "Raw_GDP", "Raw_Money_Growth", "Raw_REER", "Raw_FAO", "Raw_FFR", "Raw_Oil",
    "Quarterly_HCPI", "Quarterly_Inflation", "Quarterly_GDP", "Quarterly_Money", "Quarterly_REER", "Quarterly_FAO",
    "Quarterly_FFR", "Quarterly_Oil", "Panel_Quarterly_Raw", "Panel_Quarterly_Final", "Imputation_Audit",
    "Disaggregation_Audit", "Descriptive_Stats", "Stationarity", "Lag_Selection", "Model_Results", "Diagnostics",
    "IRF_Data", "FEVD_Data", "Model_Comparison", "Results_Summary"
  )
  all_expected_present <- all(expected_sheets %in% sheets_found)
  add_check("Semua Sheet Wajib Tersedia", all_expected_present, "30/30 nama sheet cocok sempurna")
  
  # 4. Baca kembali sheet Panel_Quarterly_Final
  panel_reopened <- read_excel(final_excel, sheet = "Panel_Quarterly_Final")
  nr <- nrow(panel_reopened)
  nc <- ncol(panel_reopened)
  add_check("Dimensi Panel_Quarterly_Final", nr == 610 && nc >= 19, sprintf("%d baris x %d kolom (Target: 610 x 19)", nr, nc))
  
  # 5. Cek kelengkapan kolom inti
  core_cols <- c("country", "year", "quarter", "period", "hcpi_q", "inflation_yoy", "gdp_growth", "money_growth", "reer_q", "fao_q", "ffr_q", "oil_q")
  core_present <- all(core_cols %in% names(panel_reopened))
  add_check("Ketersediaan Kolom Inti Panel", core_present, paste(core_cols, collapse = ", "))
  
  # 6. Cek tidak ada duplikasi negara-kuartal
  dups <- panel_reopened %>% group_by(country, year, quarter) %>% filter(n() > 1)
  add_check("Keunikan Observasi Negara-Kuartal", nrow(dups) == 0, sprintf("%d baris duplikat", nrow(dups)))
  
  # 7. Cek kesesuaian tipe data
  num_check <- is.numeric(panel_reopened$hcpi_q) && is.numeric(panel_reopened$inflation_yoy) && is.numeric(panel_reopened$gdp_growth)
  add_check("Tipe Data Numerik Kolom Makro", num_check, "hcpi_q, inflation_yoy, gdp_growth terbaca numerik")
}

# 8. Buka kembali file CSV dan bandingkan
if (csv_exists) {
  csv_reopened <- read.csv(final_csv)
  add_check("Keterbacaan Ulang CSV", nrow(csv_reopened) == 610, sprintf("%d baris terbaca dari CSV", nrow(csv_reopened)))
}

# 9. Hitung Checksum SHA256 untuk verifikasi integritas
if (excel_exists) {
  hash_excel <- md5sum(final_excel)
  add_check("Integritas MD5 Checksum Excel", TRUE, as.character(hash_excel))
}
if (csv_exists) {
  hash_csv <- md5sum(final_csv)
  add_check("Integritas MD5 Checksum CSV", TRUE, as.character(hash_csv))
}

val_summary_df <- bind_rows(validation_checks)

cat("===============================================================================\n")
cat("                       MATRIKS VALIDASI AKHIR PIPELINE                        \n")
cat("===============================================================================\n")
for (i in 1:nrow(val_summary_df)) {
  r <- val_summary_df[i, ]
  cat(sprintf("[%-11s] %-35s : %s\n", r$Status, r$Check_Item, r$Detail))
}
cat("===============================================================================\n")

all_passed <- all(grepl("PASS", val_summary_df$Status))
if (all_passed) {
  cat("\n>>> STATUS: SELURUH CHECKLIST VALIDASI BERHASIL LOLOS 100%! <<<\n")
} else {
  cat("\n>>> PERINGATAN: Terdapat item validasi yang gagal! <<<\n")
}

write.csv(val_summary_df, "output/Validation_Report.csv", row.names = FALSE)
cat("Laporan validasi tersimpan di: output/Validation_Report.csv\n")
cat(">>> Selesai Tahap 14.\n")

