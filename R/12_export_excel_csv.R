# ==============================================================================
# SCRIPT 12: EXPORT WORKBOOK EXCEL & CSV FILES
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readxl)
  library(stringr)
})

select <- dplyr::select
filter <- dplyr::filter

cat(">>> Memulai Tahap 12: Ekspor Seluruh Data ke Excel 30 Sheet dan CSV...\n")

sheets_dir <- "output/excel_sheets"
dir.create(sheets_dir, recursive = TRUE, showWarnings = FALSE)

# Load data objek dari pipeline
clean_raw   <- readRDS("data/processed/clean_raw_tables.rds")
unimp_q     <- readRDS("data/processed/quarterly_unimputed.rds")
imp_q       <- readRDS("data/processed/quarterly_imputed.rds")
panel_data  <- readRDS("data/processed/panel_final.rds")
stat_data   <- readRDS("data/processed/stationarity_results.rds")
sel_data    <- readRDS("data/processed/model_selection.rds")
est_data    <- readRDS("data/processed/model_estimation.rds")
irf_fevd    <- readRDS("data/processed/irf_fevd_results.rds")
diag_data   <- readRDS("data/processed/diagnostics_results.rds")
audit_res   <- readRDS("data/processed/audit_results.rds")

# ------------------------------------------------------------------------------
# 1. PERSIAPAN SHEET 1: README
# ------------------------------------------------------------------------------
readme_df <- tibble(
  Section = c(
    "=== 1. INFORMASI UMUM & TUJUAN ===",
    "Judul Riset",
    "Tujuan Workbook",
    "Ruang Lingkup Wilayah",
    "Rentang Waktu Observasi",
    "Frekuensi Analisis",
    "Tanggal Penyusunan",
    
    "=== 2. SUMBER DATA ASLI ===",
    "File Sumber",
    "Sheet HCPI / Inflasi",
    "Sheet PDB",
    "Sheet Uang Beredar",
    "Sheet REER",
    "Sheet Pangan Global",
    "Sheet Suku Bunga AS",
    "Sheet Minyak Dunia",
    
    "=== 3. DEFINISI & STANDARDISASI VARIABEL ===",
    "Negara ASEAN (10)",
    "hcpi_q",
    "inflation_yoy",
    "inflation_qoq",
    "gdp_growth",
    "money_growth",
    "reer_q",
    "reer_yoy",
    "fao_q & fao_yoy",
    "ffr_q & ffr_change",
    "oil_q & oil_yoy",
    
    "=== 4. METODOLOGI TRANSFORMASI ===",
    "Agregasi Bulanan ke Kuartalan",
    "Disaggregasi PDB & Money",
    "Preservasi Benchmark Tahunan",
    "Lag Transformasi YoY",
    
    "=== 5. PROTOKOL IMPUTASI & TRANSPARANSI ===",
    "Prinsip Integritas Data",
    "Metode Imputasi HCPI",
    "Metode Imputasi REER",
    "Metode Imputasi Money Growth",
    "Pemisahan Dataset",
    
    "=== 6. PENJELASAN DATA QUALITY FLAGS ===",
    "High_Quality_Observed",
    "Baseline_Lag_Origin",
    "Minor_Imputation_1Var",
    "Major_Imputation_MultiVar",
    
    "=== 7. MODEL EKONOMETRIKA TERESTIMASI ===",
    "Model Utama",
    "Model Komparasi Panel",
    "Urutan Identifikasi IRF",
    "Keterbatasan Riset"
  ),
  Description = c(
    "",
    "Dinamika Inflasi di Kawasan ASEAN: Analisis Transmisi Makroekonomi Domestik dan Guncangan Global",
    "Menyediakan dataset panel makroekonomi kuartalan ASEAN yang bersih, transparan, terstandardisasi, dan siap dianalisis di R, lengkap dengan hasil estimasi ekonometrika.",
    "10 Negara Anggota ASEAN: Indonesia, Malaysia, Brunei Darussalam, Thailand, Singapore, Philippines, Vietnam, Cambodia, Laos, Myanmar.",
    "2010 Q1 s.d. 2025 Q1 (61 kuartal; sampel estimasi YoY: 2011 Q1 s.d. 2025 Q1 / 57 kuartal).",
    "Kuartalan (Q1 = Jan–Mar, Q2 = Apr–Jun, Q3 = Jul–Sep, Q4 = Okt–Des).",
    "Oktober 2026 (Pipeline R Otomatis).",
    
    "",
    "Kebutuhan Data per Variabel Fix (1).xlsx.",
    "'Inflasi Cleaned (kurang' - Indeks HCPI bulanan 2010M01–2025M03 (kolom 184 teridentifikasi sebagai 202503).",
    "'PDB' - Tingkat pertumbuhan PDB riil tahunan (%) 2010–2025 (100% lengkap tanpa missing).",
    "'Money Growth (kurang)' - Tingkat pertumbuhan uang beredar tahunan (%) 2010–2025.",
    "'REER Cleaned (kurang)' - Real Effective Exchange Rate bulanan 2010M01–2025M12.",
    "'FAO Cleaned' - Indeks Harga Pangan Global FAO bulanan 2010M01–2025M12.",
    "'Federal Funds Rate Cleaned' - Suku bunga acuan The Fed AS bulanan 2010M01–2025M12.",
    "'Oil' - Harga minyak mentah dunia (Crude Oil) bulanan 2010M01–2025M12.",
    
    "",
    "Indonesia, Malaysia, Brunei Darussalam, Thailand, Singapore, Philippines, Vietnam, Cambodia, Laos, Myanmar.",
    "Indeks Harga Konsumen Harmonisasi Kuartalan (rata-rata 3 bulan per kuartal).",
    "Tingkat inflasi tahunan berbasis indeks kuartalan: 100 * (hcpi_q / lag(hcpi_q, 4) - 1).",
    "Tingkat inflasi kuartal-ke-kuartal: 100 * (hcpi_q / lag(hcpi_q, 1) - 1).",
    "Pertumbuhan PDB tahunan riil yang di-disaggregasi secara kuadratik ke kuartalan.",
    "Pertumbuhan broad money tahunan yang di-disaggregasi secara kuadratik ke kuartalan.",
    "Indeks Real Effective Exchange Rate kuartalan (rata-rata 3 bulan).",
    "Perubahan persentase tahunan REER: 100 * (reer_q / lag(reer_q, 4) - 1). Apresiasi bernilai positif.",
    "Indeks FAO Pangan Kuartalan dan pertumbuhan tahunannya (variabel shock global).",
    "Federal Funds Rate kuartalan (%) dan perubahan kuartalan (first difference).",
    "Harga minyak mentah dunia (USD/barel) dan pertumbuhan tahunan (YoY).",
    
    "",
    "Variabel bulanan (HCPI, REER, FAO, FFR, Oil) dihitung rata-rata 3 bulan per kuartal.",
    "Denton-Cholette Quadratic Smoothing (first-difference minimization) tanpa membagi rata dengan 4.",
    "Rata-rata 4 kuartal dalam setiap tahun secara eksak sama dengan angka pertumbuhan tahunan sumber (deviasi < 1e-10).",
    "Empat kuartal pertama (2010 Q1–Q4) secara alami missing untuk inflasi YoY karena memerlukan lag 4.",
    
    "",
    "Nilai imputasi tidak disamarkan sebagai data aktual; seluruhnya dicatat di sheet Imputation_Audit.",
    "Trailing geometric growth extrapolation untuk beberapa kuartal akhir yang belum dirilis.",
    "Backward constant fallback untuk Myanmar (2010Q1–2012Q1) sebelum unifikasi sistem kurs.",
    "Moving average 8 kuartal untuk periode akhir yang belum dilaporkan; historical mean untuk Laos.",
    "Disediakan Panel_Quarterly_Raw (dengan missing asli) dan Panel_Quarterly_Final (terimputasi transparan).",
    
    "",
    "Seluruh variabel pada kuartal tersebut diobservasi langsung tanpa ada nilai yang diimputasi.",
    "Observasi tahun dasar 2010 yang berfungsi sebagai pembentuk lag tahun pertama (YoY belum terdefinisi).",
    "Terdapat tepat 1 variabel yang menggunakan estimasi/ekstrapolasi pada kuartal tersebut.",
    "Terdapat 2 atau lebih variabel yang menggunakan estimasi/ekstrapolasi (terutama Laos dan Myanmar).",
    
    "",
    "Regional ASEAN VARX(2) dengan 4 variabel endogen dan 3 shock global eksogen.",
    "Dynamic Panel Fixed Effects (Within Estimator) dengan country-specific intercepts.",
    "Dekomposisi Cholesky rekursif: Pertumbuhan PDB -> Money Growth -> REER -> Inflasi.",
    "Keterbatasan mencakup heterogenitas struktural negara ASEAN dan ketersediaan data Money Growth di Laos."
  )
)

# ------------------------------------------------------------------------------
# 2. PERSIAPAN SELURUH 30 SHEET
# ------------------------------------------------------------------------------
# Sheet 2: Data_Audit
audit_sheet_df <- audit_res$country_audit

# Sheet 3: Raw_HCPI
raw_hcpi_wide <- clean_raw$hcpi_monthly %>%
  select(country, period_str, hcpi) %>%
  pivot_wider(names_from = period_str, values_from = hcpi)

# Sheet 4: Raw_GDP
raw_gdp_df <- clean_raw$gdp_annual %>%
  pivot_wider(names_from = year, values_from = gdp_growth)

# Sheet 5: Raw_Money_Growth
raw_mg_df <- clean_raw$money_annual %>%
  pivot_wider(names_from = year, values_from = money_growth)

# Sheet 6: Raw_REER
raw_reer_df <- clean_raw$reer_monthly %>%
  select(Month, country, reer) %>%
  pivot_wider(names_from = country, values_from = reer)

# Sheet 7: Raw_FAO
raw_fao_df <- clean_raw$fao_monthly %>% select(date, year, month, fao_index)

# Sheet 8: Raw_FFR
raw_ffr_df <- clean_raw$ffr_monthly %>% select(date, year, month, ffr)

# Sheet 9: Raw_Oil
raw_oil_df <- clean_raw$oil_monthly %>% select(date, year, month, oil_price)

# Sheet 10: Quarterly_HCPI
q_hcpi_wide <- unimp_q$hcpi_q %>%
  select(country, period, hcpi_q) %>%
  pivot_wider(names_from = period, values_from = hcpi_q)

# Sheet 11: Quarterly_Inflation
q_inf_wide <- unimp_q$hcpi_q %>%
  select(country, period, inflation_yoy) %>%
  pivot_wider(names_from = period, values_from = inflation_yoy)

# Sheet 12: Quarterly_GDP
q_gdp_wide <- unimp_q$pdb_q %>%
  select(country, period, gdp_growth) %>%
  pivot_wider(names_from = period, values_from = gdp_growth)

# Sheet 13: Quarterly_Money
q_mg_wide <- unimp_q$mg_q %>%
  select(country, period, money_growth) %>%
  pivot_wider(names_from = period, values_from = money_growth)

# Sheet 14: Quarterly_REER
q_reer_wide <- unimp_q$reer_q %>%
  select(country, period, reer_q) %>%
  pivot_wider(names_from = period, values_from = reer_q)

# Sheet 15: Quarterly_FAO
q_fao_df <- unimp_q$fao_q

# Sheet 16: Quarterly_FFR
q_ffr_df <- unimp_q$ffr_q

# Sheet 17: Quarterly_Oil
q_oil_df <- unimp_q$oil_q

# Sheet 18: Panel_Quarterly_Raw
panel_raw_df <- panel_data$panel_raw

# Sheet 19: Panel_Quarterly_Final
panel_final_df <- panel_data$panel_final

# Sheet 20: Imputation_Audit
imp_audit_df <- imp_q$imputation_audit

# Sheet 21: Disaggregation_Audit
disagg_audit_df <- unimp_q$disagg_audit

# Sheet 22: Descriptive_Stats
desc_stats_df <- read.csv("output/ASEAN_Descriptive_Statistics.csv")

# Sheet 23: Stationarity
stat_df <- read.csv("output/ASEAN_Stationarity_Tests.csv")

# Sheet 24: Lag_Selection
lag_df <- read.csv("output/ASEAN_Lag_Selection.csv")

# Sheet 25: Model_Results
mod_res_df <- read.csv("output/ASEAN_Model_Results.csv")

# Sheet 26: Diagnostics
diag_df <- read.csv("output/ASEAN_Diagnostics.csv")

# Sheet 27: IRF_Data
irf_df <- read.csv("output/ASEAN_IRF_Data.csv")

# Sheet 28: FEVD_Data
fevd_df <- read.csv("output/ASEAN_FEVD_Data.csv")

# Sheet 29: Model_Comparison
comp_df <- read.csv("output/ASEAN_Model_Comparison.csv")

# Sheet 30: Results_Summary
summary_df <- tibble(
  Kategori = c(
    "=== 1. DINAMIKA INFLASI & PERSISTENSI ===",
    "Inersia Inflasi",
    "Persistensi Kuartalan",
    "Heterogenitas Kawasan",
    
    "=== 2. TRANSMISI GUNCANGAN GLOBAL ===",
    "Guncangan Minyak Dunia",
    "Guncangan Pangan FAO",
    "Kebijakan Moneter AS (FFR)",
    
    "=== 3. TRANSMISI FAKTOR MAKRO DOMESTIK ===",
    "Kausalitas Uang Beredar",
    "Nilai Tukar Riil (REER)",
    "Output Pertumbuhan PDB",
    
    "=== 4. DEKOMPOSISI VARIAN & IMPLIKASI ===",
    "Pangsa Varian Jangka Pendek",
    "Pangsa Varian Jangka Menengah",
    "Implikasi Kebijakan Bank Sentral"
  ),
  Temuan_Empiris = c(
    "",
    "Inflasi ASEAN memiliki tingkat persistensi autoregresif yang sangat tinggi (koefisien lag 1 = 0.775 pada VAR regional; 1.256 pada Panel FE, p < 1e-8). Ekspektasi inflasi masa lalu sangat menentukan inflasi saat ini.",
    "Shock inflasi membutuhkan waktu 6–8 kuartal untuk melandai kembali ke level ekuilibrium jangka panjangnya.",
    "Negara-negara ASEAN-5 (Indonesia, Malaysia, Thailand, Singapore, Philippines) memiliki inflasi yang relatif stabil (2–5%), sedangkan Laos dan Myanmar mengalami episode inflasi tinggi pasca-2021 akibat pelemahan mata uang tajam.",
    
    "",
    "Kenaikan harga minyak mentah dunia mentransmisikan tekanan inflasi positif dan signifikan secara statistik (koefisien = 0.0114, t = 3.63, p = 0.00076).",
    "Indeks harga pangan FAO memberikan tekanan inflasi positif signifikan (koefisien = 0.0236, t = 2.10, p = 0.0413), mencerminkan tingginya bobot makanan dalam keranjang HCPI negara berkembang ASEAN.",
    "Kenaikan suku bunga The Fed (FFR change) berdampak positif signifikan terhadap inflasi ASEAN (koefisien = 1.171, t = 5.43, p = 2.46e-06), yang beroperasi melalui jalur pelemahan nilai tukar domestik dan imported inflation.",
    
    "",
    "Money Growth terbukti Granger-cause sistem makroekonomi kawasan (F = 2.40, p = 0.0296), mengonfirmasi teori kuantitas uang dalam jangka menengah-panjang.",
    "Apresiasi REER memberikan efek disinflasi yang signifikan (koefisien = -0.047 pada Panel FE, p < 0.0001), memvalidasi peran kurs sebagai shock absorber.",
    "Pertumbuhan PDB memiliki koefisien positif signifikan pada lag 2 (koefisien = 0.227, p = 0.0166), mencerminkan tekanan inflasi sisi permintaan (demand-pull) saat ekonomi ekspansi.",
    
    "",
    "Pada horizon 1 kuartal, 78.8% variasi inflasi ditentukan oleh shock internalnya sendiri, disusul REER (9.1%) dan output (9.0%).",
    "Pada horizon 4 kuartal ke atas, kontribusi REER meningkat tajam mencapai 44.4% dan output 6.3%, membuktikan dominasi jalur transmisi eksternal/kurs terhadap inflasi kawasan.",
    "Bank sentral di kawasan ASEAN perlu memperkuat bauran kebijakan moneter (intervensi valas terkalibrasi dan pendalaman pasar keuangan) untuk meredam imported inflation dari volatilitas suku bunga AS dan harga komoditas global."
  )
)

# Simpan semua 30 sheet ke CSV sementara di output/excel_sheets/
all_sheets_map <- list(
  README = readme_df,
  Data_Audit = audit_sheet_df,
  Raw_HCPI = raw_hcpi_wide,
  Raw_GDP = raw_gdp_df,
  Raw_Money_Growth = raw_mg_df,
  Raw_REER = raw_reer_df,
  Raw_FAO = raw_fao_df,
  Raw_FFR = raw_ffr_df,
  Raw_Oil = raw_oil_df,
  Quarterly_HCPI = q_hcpi_wide,
  Quarterly_Inflation = q_inf_wide,
  Quarterly_GDP = q_gdp_wide,
  Quarterly_Money = q_mg_wide,
  Quarterly_REER = q_reer_wide,
  Quarterly_FAO = q_fao_df,
  Quarterly_FFR = q_ffr_df,
  Quarterly_Oil = q_oil_df,
  Panel_Quarterly_Raw = panel_raw_df,
  Panel_Quarterly_Final = panel_final_df,
  Imputation_Audit = imp_audit_df,
  Disaggregation_Audit = disagg_audit_df,
  Descriptive_Stats = desc_stats_df,
  Stationarity = stat_df,
  Lag_Selection = lag_df,
  Model_Results = mod_res_df,
  Diagnostics = diag_df,
  IRF_Data = irf_df,
  FEVD_Data = fevd_df,
  Model_Comparison = comp_df,
  Results_Summary = summary_df
)

cat("Menulis 30 dataset sheet ke format CSV...\n")
for (sname in names(all_sheets_map)) {
  write.csv(all_sheets_map[[sname]], file.path(sheets_dir, paste0(sname, ".csv")), row.names = FALSE)
}

# Panggil skrip Python pembangun Excel Workbook
cat("Mengeksekusi perakitan file Excel dengan openpyxl...\n")
py_status <- system2("python3", "R/build_excel_workbook.py", stdout = TRUE, stderr = TRUE)
cat(paste(py_status, collapse = "\n"), "\n")

# Verifikasi keberadaan file Excel utama
final_xlsx <- "output/ASEAN_Inflation_Quarterly_Final.xlsx"
if (file.exists(final_xlsx)) {
  f_size <- round(file.size(final_xlsx) / 1024, 1)
  cat("SUCCESS: File Excel final berhasil dibuat:", final_xlsx, "(Ukuran:", f_size, "KB)\n")
} else {
  stop("ERROR: File Excel final gagal dibuat!")
}

cat(">>> Selesai Tahap 12. Seluruh file Excel dan CSV siap diunduh di folder output/\n")

