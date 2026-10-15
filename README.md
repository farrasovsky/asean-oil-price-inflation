# Riset Dinamika Inflasi Negara-Negara ASEAN (2010–2025)

Proyek ekonometrika komprehensif untuk menganalisis dinamika, persistensi, dan transmisi inflasi di 10 negara anggota ASEAN (*Indonesia, Malaysia, Brunei Darussalam, Thailand, Singapore, Philippines, Vietnam, Cambodia, Laos, Myanmar*) menggunakan pendekatan **Panel Ekonometrika**, **Regional VARX(2)**, **Dynamic Panel Fixed Effects**, serta **Temporal Disaggregation Denton-Cholette**.

---

## 📁 Struktur Direktori Proyek

```text
olah_oil/
├── Kebutuhan Data per Variabel Fix (1).xlsx    # File sumber Excel asli
├── run_all.R                                   # Master runner pipeline eksekusi end-to-end
├── README.md                                   # Panduan dan dokumentasi proyek
├── data/
│   ├── raw/                                    # Salinan data sumber asli
│   └── processed/                              # Data RDS perantara (clean_raw, quarterly, panel)
├── R/
│   ├── 01_audit_data.R                         # Audit awal struktur sheet & kualitas data
│   ├── 02_clean_data.R                         # Pembersihan & standardisasi nama negara & tanggal
│   ├── 03_quarterly_transformation.R           # Agregasi HCPI/REER & Disaggregasi PDB/Money (Denton)
│   ├── 04_imputation.R                         # Protokol imputasi transparan & pencatatan audit
│   ├── 05_panel_dataset.R                      # Pembentukan dataset panel final & agregat regional
│   ├── 06_descriptive_analysis.R               # Statistik deskriptif & 7 visualisasi publikasi
│   ├── 07_stationarity_tests.R                 # Uji Pesaran CD & Uji Panel/Time Series Unit Root
│   ├── 08_model_selection.R                    # Pemilihan lag optimal & Uji Kointegrasi Johansen
│   ├── 09_model_estimation.R                   # Estimasi Regional VARX(2) & Dynamic Panel FE
│   ├── 10_irf_fevd.R                           # Perhitungan IRF Cholesky & FEVD 12 Kuartal
│   ├── 11_diagnostics.R                        # Stabilitas sistem, Portmanteau, ARCH, & Sensitivitas
│   ├── 12_export_excel_csv.R                   # Ekspor dataset 30 sheet Excel & CSV
│   ├── 13_generate_report.R                    # Kompilasi laporan penelitian akademik (HTML)
│   ├── 14_validation.R                         # Pengujian validasi & verifikasi integritas ulang
│   └── build_excel_workbook.py                 # Engine openpyxl perakitan Excel 30 sheet
├── output/
│   ├── ASEAN_Inflation_Quarterly_Final.xlsx     # WORKBOOK EXCEL FINAL (30 Sheet, Styled)
│   ├── Data_Audit.xlsx                         # WORKBOOK AUDIT SUMBER LENGKAP
│   ├── ASEAN_Inflation_Quarterly_Final.csv      # DATASET FINAL PANEL (610 Baris x 19 Kolom)
│   ├── ASEAN_Inflation_Quarterly_Raw.csv        # Dataset panel mentah (dengan missing alami)
│   ├── ASEAN_Regional_Quarterly.csv            # Dataset agregat kawasan ASEAN
│   ├── ASEAN_Imputation_Audit.csv              # Log audit seluruh titik imputasi (191 entri)
│   ├── ASEAN_Disaggregation_Audit.csv          # Log audit disaggregasi PDB & Money (286 entri)
│   ├── ASEAN_Descriptive_Statistics.csv        # Statistik deskriptif lengkap per variabel
│   ├── ASEAN_Stationarity_Tests.csv            # Hasil uji Pesaran CD & Unit Root
│   ├── ASEAN_Lag_Selection.csv                 # Kriteria AIC, HQ, SC, FPE
│   ├── ASEAN_Cointegration_Test.csv            # Hasil uji kointegrasi Johansen
│   ├── ASEAN_Model_Results.csv                 # Koefisien, SE, t-stat, p-value model
│   ├── ASEAN_Granger_Causality.csv             # Hasil uji kausalitas prediktif Granger
│   ├── ASEAN_Diagnostics.csv                   # Uji stabilitas, korelasi serial, ARCH, normalitas
│   ├── ASEAN_IRF_Data.csv                      # Data numerik respons impuls 12 kuartal (95% CI)
│   ├── ASEAN_FEVD_Data.csv                     # Dekomposisi varians kesalahan prediksi
│   ├── ASEAN_Model_Comparison.csv              # Perbandingan sensitivitas lintas spesifikasi
│   ├── Validation_Report.csv                   # Matriks checklist validasi kualitas
│   └── figures/                                # 9 Grafik visualisasi beresolusi tinggi (300 DPI)
└── reports/
    ├── Laporan_Inflasi_ASEAN.html              # Laporan penelitian akademik lengkap (Bab I - V)
    └── Panduan_Statistik_Mudah_Inflasi_ASEAN.html # Panduan statistik & ekonometrika versi bahasa awam/super mudah
```

---

## 📊 Daftar 30 Sheet dalam Workbook Final (`ASEAN_Inflation_Quarterly_Final.xlsx`)

1. **`README`**: Dokumentasi lengkap tujuan, sumber, definisi variabel, metode agregasi, protokol imputasi, arti flag kualitas data, dan model terestimasi.
2. **`Data_Audit`**: Ringkasan audit per variabel dan negara pada file Excel sumber.
3. **`Raw_HCPI`**: Data mentah Indeks HCPI bulanan (2010M01–2025M03).
4. **`Raw_GDP`**: Data mentah Pertumbuhan PDB riil tahunan (%) 2010–2025.
5. **`Raw_Money_Growth`**: Data mentah Pertumbuhan Uang Beredar tahunan (%) 2010–2025.
6. **`Raw_REER`**: Data mentah Real Effective Exchange Rate bulanan (2010M01–2025M12).
7. **`Raw_FAO`**: Data mentah Indeks Harga Pangan FAO bulanan.
8. **`Raw_FFR`**: Data mentah Federal Funds Rate bulanan.
9. **`Raw_Oil`**: Data mentah Harga Minyak Mentah Dunia bulanan.
10. **`Quarterly_HCPI`**: Indeks HCPI kuartalan terstandarisasi.
11. **`Quarterly_Inflation`**: Laju inflasi tahunan (YoY) dan kuartalan (QoQ).
12. **`Quarterly_GDP`**: Pertumbuhan PDB kuartalan hasil disaggregasi Denton-Cholette.
13. **`Quarterly_Money`**: Pertumbuhan broad money kuartalan hasil disaggregasi.
14. **`Quarterly_REER`**: Indeks REER kuartalan dan laju perubahannya.
15. **`Quarterly_FAO`**: Indeks FAO kuartalan dan pertumbuhan tahunan.
16. **`Quarterly_FFR`**: Federal Funds Rate kuartalan dan perubahannya (first difference).
17. **`Quarterly_Oil`**: Harga minyak mentah kuartalan dan pertumbuhan tahunan.
18. **`Panel_Quarterly_Raw`**: Dataset panel kuartalan mentah (missing data alami dipertahankan).
19. **`Panel_Quarterly_Final`**: Dataset panel final lengkap dengan `imputation_count` dan `data_quality_flag`.
20. **`Imputation_Audit`**: Log transparansi audit setiap titik data yang diimputasi.
21. **`Disaggregation_Audit`**: Log verifikasi matematis disaggregasi temporal kuadratik.
22. **`Descriptive_Stats`**: N, Mean, SD, Median, Min, Max, Skewness, Kurtosis per entitas.
23. **`Stationarity`**: Uji ketergantungan lintas bagian Pesaran CD dan uji akar unit (LLC, Fisher ADF, KPSS).
24. **`Lag_Selection`**: Tabel evaluasi lag order (AIC, HQ, SC, FPE).
25. **`Model_Results`**: Koefisien estimasi, Standard Error, t-stat, p-value model VARX dan Panel FE.
26. **`Diagnostics`**: Uji stabilitas akar karakteristik, korelasi serial, heteroskedastisitas ARCH, dan normalitas.
27. **`IRF_Data`**: Titik estimasi dan interval keyakinan 95% respons impuls 12 kuartal.
28. **`FEVD_Data`**: Persentase kontribusi varians prediksi inflasi horizon 1–12 kuartal.
29. **`Model_Comparison`**: Perbandingan kekokohan (sensitivitas lag, periode sampel, core panel).
30. **`Results_Summary`**: Ringkasan eksekutif temuan empiris dan rekomendasi kebijakan moneter.

---

## 🚀 Cara Menjalankan Ulang Pipeline

Cukup jalankan satu perintah berikut di terminal:

```bash
Rscript run_all.R
```

Skrip ini akan secara otomatis mengeksekusi seluruh 14 skrip pengolahan data, membangun visualisasi, merakit file Excel 30 sheet, menyusun laporan HTML, dan memverifikasi integritas seluruh berkas.

