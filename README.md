# Riset Dinamika Inflasi Negara-Negara ASEAN (2010–2025)

Proyek ekonometrika komprehensif untuk menganalisis dinamika, persistensi, dan transmisi inflasi di 10 negara anggota ASEAN (*Indonesia, Malaysia, Brunei Darussalam, Thailand, Singapore, Philippines, Vietnam, Cambodia, Laos, Myanmar*) menggunakan pendekatan **Panel Ekonometrika**, **Regional VARX(2)**, **Dynamic Panel Fixed Effects**, serta **Temporal Disaggregation Denton-Cholette**.

---

## 🛠️ Panduan Cepat Menjalankan Proyek di Komputer Lokal (Bagi Pemula / Orang Awam)

Jika Anda baru pertama kali mengunduh atau meng-clone proyek ini ke komputer Anda, ikuti 3 langkah mudah berikut:

### 1. Prasyarat Sistem
Pastikan di komputer Anda sudah terpasang:
* **R** (versi $\ge$ 4.0.0) — Unduh gratis di [cran.r-project.org](https://cran.r-project.org/)
* **Python** (versi $\ge$ 3.8) — Unduh gratis di [python.org](https://www.python.org/)
* *(Opsional)* **RStudio** — Unduh gratis di [posit.co](https://posit.co/)

---

### 2. Langkah 1: Instalasi Semua Paket R (Cukup 1 Klik / Perintah)
Buka terminal di folder proyek ini, lalu jalankan:

```bash
Rscript install_packages.R
```

> **Jika Anda menggunakan RStudio:**  
> Cukup buka file `install_packages.R`, lalu klik tombol **"Source"** di pojok kanan atas editor.  
> Skrip akan secara otomatis memeriksa dan menginstal semua paket R yang belum ada dari repositori resmi CRAN.

---

### 3. Langkah 2: Instalasi Dependensi Python (Untuk Perakitan File Excel)
Jalankan perintah ini di terminal:

```bash
pip install -r requirements.txt
```
*(Paket yang diinstal hanya `pandas`, `openpyxl`, dan `numpy` untuk membangun workbook Excel 30-sheet berformat elegan).*

---

### 4. Langkah 3: Eksekusi Seluruh Pipeline Riset
Setelah semua paket terpasang, jalankan:

```bash
Rscript run_all.R
```

Skrip ini akan secara otomatis:
1. Membaca dan mengaudit data mentah Excel sumber.
2. Membersihkan dan menstandardisasi data 10 negara ASEAN.
3. Melakukan transformasi kuartalan dan disaggregasi PDB & Money Growth (Denton-Cholette).
4. Menambal missing data secara transparan dan mencatat log auditnya.
5. Membentuk dataset panel final 610 baris observasi.
6. Menghitung statistik deskriptif dan menghasilkan 9 grafik resolusi tinggi (300 DPI).
7. Menjalankan uji Pesaran CD, Panel Unit Root, dan Kointegrasi Johansen.
8. Mengestimasi model Regional VARX(2) dan Dynamic Panel Fixed Effects.
9. Menghitung respons impuls (IRF 12 kuartal) dan varians prediksi (FEVD).
10. Menjalankan uji kestabilan sistem, korelasi serial, ARCH, dan normalitas.
11. Merakit workbook Excel 30-sheet (`ASEAN_Inflation_Quarterly_Final.xlsx`) dan file CSV.
12. Menyusun laporan penelitian ilmiah dalam format HTML.
13. Melakukan validasi akhir otomatis 14 checklist integritas file.

---

## 📦 Daftar Paket yang Digunakan & Fungsinya

### A. Paket R (`install_packages.R`)
| Nama Paket | Fungsi Utama dalam Proyek Ini |
|---|---|
| **`readxl`** | Membaca sheet data mentah dari file Excel sumber. |
| **`dplyr`** | Manipulasi data tabel, filtering, agregasi, dan pengurutan data panel. |
| **`tidyr`** | Mengubah format data dari wide ke long dan sebaliknya. |
| **`stringr`** | Standardisasi penulisan nama negara dan format kode tanggal. |
| **`lubridate`** | Operasi kalender waktu, tahun, bulan, dan penentuan kuartal. |
| **`zoo`** | Operasi deret waktu kuartalan, perhitungan moving average, dan penanganan NA. |
| **`ggplot2`** | Membuat 9 visualisasi grafik berstandar publikasi ilmiah (300 DPI). |
| **`plm`** | Analisis ekonometrika data panel (Uji Pesaran CD, Panel Unit Root, Dynamic Panel FE). |
| **`vars`** | Estimasi Vector Autoregression (VARX), pemilihan lag, IRF Cholesky, dan FEVD. |
| **`urca`** | Uji kointegrasi multivariat Johansen (Trace & Maximum Eigenvalue). |
| **`tseries`** | Uji stasioneritas ADF (Augmented Dickey-Fuller) dan KPSS. |
| **`knitr`** | Pemformatan tabel dan kompilasi laporan riset. |

### B. Paket Python (`requirements.txt`)
| Nama Paket | Fungsi Utama dalam Proyek Ini |
|---|---|
| **`openpyxl`** | Membangun workbook Excel 30 sheet dengan styling Navy header, freeze panes, autofilter, dan conditional formatting. |
| **`pandas`** | Membaca dataset tabel perantara untuk diekspor ke format Excel. |
| **`numpy`** | Operasi numerik pendukung perataan data. |

---

## 📁 Struktur Direktori Proyek

```text
olah_oil/
├── Kebutuhan Data per Variabel Fix (1).xlsx    # File sumber Excel asli
├── install_packages.R                          # Skrip instalasi otomatis paket R untuk pengguna baru
├── requirements.txt                            # Daftar dependensi Python
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
