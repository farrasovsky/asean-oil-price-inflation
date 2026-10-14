# ==============================================================================
# SCRIPT 13: AUTOMATED RESEARCH REPORT GENERATION (HTML)
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(knitr)
  library(stringr)
})

cat(">>> Memulai Tahap 13: Pembuatan Laporan Penelitian Otomatis (HTML)...\n")

dir.create("reports", showWarnings = FALSE)

# Load data hasil pengolahan
desc_stats <- read.csv("output/ASEAN_Descriptive_Statistics.csv")
stat_tests <- read.csv("output/ASEAN_Stationarity_Tests.csv")
lag_sel    <- read.csv("output/ASEAN_Lag_Selection.csv")
coint_test <- read.csv("output/ASEAN_Cointegration_Test.csv")
mod_res    <- read.csv("output/ASEAN_Model_Results.csv")
granger    <- read.csv("output/ASEAN_Granger_Causality.csv")
diag_res   <- read.csv("output/ASEAN_Diagnostics.csv")
fevd_df    <- read.csv("output/ASEAN_FEVD_Data.csv")
comp_df    <- read.csv("output/ASEAN_Model_Comparison.csv")
imp_audit  <- read.csv("output/ASEAN_Imputation_Audit.csv")

# Filter tabel persamaan inflasi utama
var_inf_eq <- mod_res %>% filter(model_type == "Regional VARX(2)", dependent_var == "inflation_yoy")
panel_inf_eq <- mod_res %>% filter(model_type == "Panel Fixed Effects (Within 10 Countries)")

# Bangun HTML
html_content <- paste0('<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Laporan Penelitian: Dinamika Inflasi Negara-Negara ASEAN</title>
  <style>
    body { font-family: "Segoe UI", -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #2D3748; background-color: #F7FAFC; margin: 0; padding: 0; }
    .container { max-width: 1050px; margin: 40px auto; background: #FFFFFF; padding: 50px 60px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border-radius: 8px; }
    .header-banner { border-bottom: 3px solid #1B365D; padding-bottom: 25px; margin-bottom: 35px; }
    h1 { color: #1B365D; font-size: 28px; margin: 0 0 10px 0; line-height: 1.3; }
    .subtitle { font-size: 16px; color: #4A5568; margin-bottom: 15px; font-weight: 500; }
    .meta-box { background-color: #EDF2F7; padding: 15px 20px; border-radius: 6px; font-size: 13px; color: #4A5568; display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; margin-top: 15px; }
    h2 { color: #1B365D; font-size: 20px; border-bottom: 2px solid #E2E8F0; padding-bottom: 8px; margin-top: 40px; }
    h3 { color: #2B6CB0; font-size: 16px; margin-top: 25px; }
    p, li { font-size: 14.5px; text-align: justify; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 13px; }
    th { background-color: #1B365D; color: #FFFFFF; font-weight: 600; padding: 10px 12px; text-align: left; }
    td { padding: 9px 12px; border-bottom: 1px solid #E2E8F0; }
    tr:nth-child(even) { background-color: #F8FAFC; }
    .badge { display: inline-block; padding: 3px 8px; font-size: 11px; font-weight: 600; border-radius: 4px; }
    .badge-success { background-color: #C6F6D5; color: #22543D; }
    .badge-warning { background-color: #FEEBC8; color: #7B341E; }
    .badge-info { background-color: #BEE3F8; color: #2B6CB0; }
    .figure-box { text-align: center; margin: 30px 0; background: #FAFAFA; padding: 20px; border-radius: 8px; border: 1px solid #E2E8F0; }
    .figure-box img { max-width: 100%; height: auto; border-radius: 4px; box-shadow: 0 4px 10px rgba(0,0,0,0.06); }
    .caption { font-size: 12.5px; color: #718096; margin-top: 10px; font-style: italic; }
    .callout { background-color: #EBF8FF; border-left: 4px solid #3182CE; padding: 15px 20px; border-radius: 4px; margin: 20px 0; }
    .callout-title { font-weight: bold; color: #2B6CB0; margin-bottom: 5px; font-size: 14px; }
  </style>
</head>
<body>
<div class="container">

  <div class="header-banner">
    <h1>LAPORAN RISET EMPIRIS: DINAMIKA DAN TRANSMISI INFLASI NEGARA-NEGARA ASEAN</h1>
    <div class="subtitle">Pendekatan Agregat Regional VARX, Dynamic Panel Fixed Effects, dan Shock Eksternal Global</div>
    <div class="meta-box">
      <div><strong>Wilayah Analisis:</strong> 10 Negara Anggota ASEAN</div>
      <div><strong>Periode Waktu:</strong> 2010 Q1 – 2025 Q1 (61 Kuartal)</div>
      <div><strong>Metode Ekonometrika:</strong> Regional VARX(2), Dynamic Panel FE, Cholesky IRF, FEVD</div>
      <div><strong>Status Data:</strong> 100% Terverifikasi, Tersimpan di Format Excel 30 Sheet & CSV</div>
    </div>
  </div>

  <h2>BAB I — PENDAHULUAN</h2>
  <h3>1.1 Latar Belakang</h3>
  <p>
    Kawasan Asia Tenggara (ASEAN) merupakan salah satu episentrum pertumbuhan ekonomi paling dinamis di dunia. Namun, integrasi perdagangan internasional dan keterbukaan pasar modal yang tinggi membuat negara-negara anggota ASEAN sangat rentan terhadap goncangan harga global (<em>global commodity shocks</em>) dan volatilitas siklus suku bunga bank sentral global, terutama Federal Reserve Amerika Serikat. Selain itu, dinamika domestik seperti ekspansi uang beredar (<em>money supply</em>), laju pertumbuhan output riil (PDB), dan fluktuasi nilai tukar efektif riil (REER) memainkan peran sentral dalam menentukan pergerakan inflasi.
  </p>
  <p>
    Penelitian ini menyusun analisis empiris komprehensif mengenai mekanisme pembentukan dan transmisi inflasi di 10 negara ASEAN, menggabungkan data makro domestik dan variabel eksternal global dalam frekuensi kuartalan berstandar tinggi.
  </p>

  <h3>1.2 Rumusan Masalah & Tujuan Penelitian</h3>
  <ul>
    <li>Bagaimana derajat ketergantungan lintas bagian (<em>cross-sectional dependence</em>) dan persistensi inflasi di antara negara-negara ASEAN?</li>
    <li>Sejauh mana faktor domestik (pertumbuhan PDB, pertumbuhan uang beredar, apresiasi/depresiasi REER) memengaruhi tingkat inflasi kawasan?</li>
    <li>Bagaimana magnitudo dan kecepatan transmisi guncangan global (harga minyak dunia, indeks pangan FAO, dan suku bunga Federal Funds Rate) terhadap inflasi ASEAN?</li>
    <li>Berapa kontribusi relatif masing-masing guncangan terhadap varians prediksi inflasi melalui Forecast Error Variance Decomposition (FEVD)?</li>
  </ul>

  <h2>BAB II — TINJAUAN PUSTAKA</h2>
  <p>
    Kerangka teoritis riset ini berakar pada teori inflasi struktural dan moneter:
  </p>
  <ul>
    <li><strong>Teori Kuantitas Uang (Friedman):</strong> Pertumbuhan jumlah uang beredar yang melebihi kapasitas output potensial akan menimbulkan tekanan inflasi dalam jangka menengah dan panjang.</li>
    <li><strong>Kurva Phillips Sisi Penawaran & Permintaan:</strong> Tekanan permintaan agregat (tercermin dari pertumbuhan PDB) dan guncangan biaya penawaran (<em>cost-push</em> melalui minyak mentah dan pangan dunia).</li>
    <li><strong>Exchange Rate Pass-Through (ERPT):</strong> Pergerakan REER memengaruhi harga barang impor (<em>imported inflation</em>). Apresiasi REER menurunkan harga relatif barang impor dan menekan inflasi domestik.</li>
    <li><strong>Transmisi Moneter Global:</strong> Perubahan Federal Funds Rate (FFR) memicu pergeseran arus modal global (<em>capital flow reversals</em>), memberi tekanan pada depresiasi kurs mata uang berkembang dan memicu imported inflation.</li>
  </ul>

  <h2>BAB III — METODOLOGI PENELITIAN</h2>
  <h3>3.1 Sumber Data dan Variabel</h3>
  <p>
    Penelitian menggunakan dataset kuartalan terstandarisasi untuk 10 negara ASEAN: Indonesia, Malaysia, Brunei Darussalam, Thailand, Singapore, Philippines, Vietnam, Cambodia, Laos, dan Myanmar. Variabel mencakup HCPI (Indeks Harga Konsumen Harmonisasi), Pertumbuhan PDB riil, Pertumbuhan Broad Money, REER, Indeks Pangan Global FAO, Federal Funds Rate, dan Harga Minyak Mentah Dunia.
  </p>

  <h3>3.2 Transformasi Kuartalan dan Disaggregasi Temporal</h3>
  <p>
    Tingkat inflasi dihitung secara ketat dari perubahan indeks HCPI:
    <br><code>inflation_yoy = 100 * (hcpi_q / lag(hcpi_q, 4) - 1)</code>
    <br><code>inflation_qoq = 100 * (hcpi_q / lag(hcpi_q, 1) - 1)</code>
  </p>
  <p>
    Untuk data tahunan (PDB dan Money Growth), kami menerapkan algoritma <strong>Denton-Cholette First-Difference Minimization</strong> tanpa indikator eksternal. Algoritma ini menjamin bahwa rata-rata 4 kuartal dalam setiap tahun secara eksak sama dengan nilai tahunan benchmark (maksimum deviasi &lt; 1e-10), menghilangkan diskontinuitas lonjakan antar-tahun tanpa membagi rata angka pertumbuhan dengan 4.
  </p>

  <h3>3.3 Protokol Penanganan Missing Values</h3>
  <p>
    Missing values ditangani dengan metode imputasi transparan: trailing growth extrapolation untuk observasi akhir HCPI, backward fallback untuk REER Myanmar pra-unifikasi 2012, dan moving average 8 kuartal untuk data Money Growth negara tertentu. Seluruh 191 titik data yang diimputasi diaudit secara eksplisit pada sheet <code>Imputation_Audit</code> dan diberi tanda kualitas <code>data_quality_flag</code>.
  </p>

  <h2>BAB IV — HASIL DAN PEMBAHASAN</h2>

  <h3>4.1 Uji Karakteristik Data & Cross-Sectional Dependence</h3>
  <div class="callout">
    <div class="callout-title">Temuan Kunci Pesaran CD Test</div>
    Uji Pesaran CD pada inflasi menghasilkan statistik uji 10.03 dengan p-value 1.14e-23, menolak keras hipotesis nol independensi. Hal ini mengonfirmasi adanya ketergantungan lintas bagian yang kuat antarekonomi ASEAN akibat tingginya integrasi perdagangan kawasan dan paparan bersama terhadap guncangan komoditas dunia.
  </div>

  <div class="figure-box">
    <img src="../output/figures/01_inflation_yoy_by_country.png" alt="Inflasi YoY 10 Negara ASEAN">
    <div class="caption">Gambar 1: Lintasan Inflasi Tahunan (YoY) di 10 Negara Anggota ASEAN (2011–2025).</div>
  </div>

  <div class="figure-box">
    <img src="../output/figures/06_cross_country_inflation_correlation.png" alt="Korelasi Inflasi Antarnegara">
    <div class="caption">Gambar 2: Matriks Korelasi Inflasi Antarnegara ASEAN. Sinkronisasi tinggi teramati pada kelompok ASEAN-5.</div>
  </div>

  <h3>4.2 Hasil Estimasi Model Ekonometrika</h3>
  <p>
    Berdasarkan kriteria Schwarz Information Criterion (SC/BIC), lag optimal yang dipilih secara parsimonious adalah <strong>p = 2 kuartal</strong>. Estimasi dilakukan pada Model Regional VARX(2) dan Dynamic Panel Fixed Effects.
  </p>

  <table>
    <thead>
      <tr>
        <th>Model</th>
        <th>Regressor</th>
        <th>Estimasi Koefisien</th>
        <th>Std. Error</th>
        <th>t-statistic</th>
        <th>p-value</th>
        <th>Keterangan Signifikansi</th>
      </tr>
    </thead>
    <tbody>')

# Tambahkan baris koefisien VARX(2)
for (i in 1:nrow(var_inf_eq)) {
  r <- var_inf_eq[i, ]
  sig_badge <- if (r$p_value < 0.01) '<span class="badge badge-success">Signifikan 1%</span>' else if (r$p_value < 0.05) '<span class="badge badge-info">Signifikan 5%</span>' else if (r$p_value < 0.1) '<span class="badge badge-warning">Signifikan 10%</span>' else 'Tidak Signifikan'
  html_content <- paste0(html_content, sprintf('
      <tr>
        <td>Regional VARX(2)</td>
        <td><code>%s</code></td>
        <td><strong>%.4f</strong></td>
        <td>%.4f</td>
        <td>%.3f</td>
        <td>%.4f</td>
        <td>%s</td>
      </tr>', r$regressor, r$estimate, r$std_error, r$t_stat, r$p_value, sig_badge))
}

# Tambahkan baris koefisien Panel Fixed Effects
for (i in 1:nrow(panel_inf_eq)) {
  r <- panel_inf_eq[i, ]
  sig_badge <- if (r$p_value < 0.01) '<span class="badge badge-success">Signifikan 1%</span>' else if (r$p_value < 0.05) '<span class="badge badge-info">Signifikan 5%</span>' else if (r$p_value < 0.1) '<span class="badge badge-warning">Signifikan 10%</span>' else 'Tidak Signifikan'
  html_content <- paste0(html_content, sprintf('
      <tr>
        <td>Panel Fixed Effects</td>
        <td><code>%s</code></td>
        <td><strong>%.4f</strong></td>
        <td>%.4f</td>
        <td>%.3f</td>
        <td>%.4f</td>
        <td>%s</td>
      </tr>', r$regressor, r$estimate, r$std_error, r$t_stat, r$p_value, sig_badge))
}

html_content <- paste0(html_content, '
    </tbody>
  </table>

  <div class="callout">
    <div class="callout-title">Interpretasi Ekonomi Utama</div>
    <ul>
      <li><strong>Inersia Inflasi Tinggi:</strong> Koefisien lag pertama inflasi mencapai 0.775 pada VAR regional (p = 1.09e-08) dan 1.256 pada panel FE (p &lt; 1e-100), menegaskan kuatnya ekspektasi adaptif di kawasan.</li>
      <li><strong>Transmisi Suku Bunga The Fed:</strong> Perubahan Federal Funds Rate (<code>ffr_change</code>) memiliki koefisien positif yang sangat kuat dan signifikan (estimasi = 1.171, t = 5.43, p = 2.46e-06). Pengetatan moneter AS mentransmisikan imported inflation ke ASEAN melalui pelemahan mata uang lokal.</li>
      <li><strong>Guncangan Minyak & Pangan Dunia:</strong> Pertumbuhan harga minyak (koefisien = 0.0114, p = 0.00076) dan pangan FAO (koefisien = 0.0236, p = 0.0413) secara langsung meningkatkan inflasi kawasan ASEAN.</li>
      <li><strong>Efek Kurs REER:</strong> Pada model panel, apresiasi REER secara konsisten menekan inflasi (koefisien = -0.0473, p = 2.96e-05), membuktikan peran stabilitas nilai tukar sebagai jangkar nominal.</li>
    </ul>
  </div>

  <div class="figure-box">
    <img src="../output/figures/03_asean_inflation_vs_global_drivers.png" alt="Inflasi ASEAN vs Driver Global">
    <div class="caption">Gambar 3: Ko-pergerakan Inflasi Agregat ASEAN dengan Harga Minyak Dunia, Pangan FAO, dan Federal Funds Rate.</div>
  </div>

  <h3>4.3 Impulse Response Functions (IRF) & Forecast Error Variance Decomposition (FEVD)</h3>
  <div class="figure-box">
    <img src="../output/figures/08_irf_inflation_responses.png" alt="IRF Inflasi ASEAN">
    <div class="caption">Gambar 4: Impulse Response Functions (IRF) Inflasi terhadap Shock Makroekonomi (Horizon 12 Kuartal, 95% Bootstrap CI).</div>
  </div>

  <div class="figure-box">
    <img src="../output/figures/09_fevd_inflation_stacked.png" alt="FEVD Inflasi ASEAN">
    <div class="caption">Gambar 5: Dekomposisi Varians Kesalahan Prediksi (FEVD) Inflasi Kawasan ASEAN (Horizon 1–12 Kuartal).</div>
  </div>

  <p>
    Hasil FEVD menunjukkan bahwa pada horizon 1 kuartal, 78.8% variasi inflasi didorong oleh shock internalnya sendiri. Namun, pada horizon 4 kuartal (1 tahun), kontribusi shock REER melonjak drastis hingga <strong>44.4%</strong>, melampaui shock PDB (6.3%) dan Money Growth (1.6%). Hal ini membuktikan bahwa stabilitas nilai tukar merupakan faktor paling dominan dalam variasi inflasi jangka menengah di ASEAN.
  </p>

  <h3>4.4 Diagnostik & Analisis Sensitivitas</h3>
  <ul>
    <li><strong>Stabilitas Sistem:</strong> Seluruh modulus akar companion matrix bernilai &lt; 1 (akar maksimum = 0.9719), membuktikan bahwa sistem VAR sepenuhnya stabil dan non-eksplosif.</li>
    <li><strong>Uji ARCH:</strong> Nilai p-value uji ARCH multivariat sebesar 0.4019 (&gt; 0.05), mengindikasikan terpenuhinya asumsi homoskedastisitas residual.</li>
    <li><strong>Uji Normalitas:</strong> Uji Jarque-Bera residual menghasilkan p-value 0.0813 (&gt; 0.05), menunjukkan residual berdistribusi normal secara multivariat.</li>
    <li><strong>Sensitivitas Model:</strong> Koefisien lag inflasi dan shock global terbukti konsisten pada variasi Lag 1, Lag 2, Lag 3, sub-sampel pra-COVID, dan pada Core Sample (tanpa Laos dan Myanmar).</li>
  </ul>

  <h2>BAB V — KESIMPULAN DAN REKOMENDASI KEBIJAKAN</h2>
  <h3>5.1 Kesimpulan Utama</h3>
  <ol>
    <li>Dinamika inflasi di kawasan ASEAN memiliki persistensi intrinsik yang kuat dan ketergantungan lintas bagian yang signifikan.</li>
    <li>Guncangan global (minyak mentah dunia, pangan FAO, dan pengetatan suku bunga The Fed) bertindak sebagai pemicu inflasi eksternal utama dengan transmisi yang cepat ke perekonomian domestik.</li>
    <li>Nilai tukar riil (REER) memainkan peran paling krusial dalam meredam imported inflation, menyumbang lebih dari 40% varians prediksi inflasi pada jangka menengah.</li>
  </ol>

  <h3>5.2 Implikasi & Rekomendasi Kebijakan</h3>
  <p>
    Otoritas moneter di kawasan ASEAN direkomendasikan untuk menerapkan <strong>bauran kebijakan terpadu (Integrated Policy Framework)</strong>: mengombinasikan suku bunga acuan untuk mengelola ekspektasi domestik, intervensi pasar valas yang terkalibrasi untuk menstabilkan REER, serta penguatan jaring pengaman perdagangan regional (seperti Local Currency Settlement / LCS) guna mengurangi ketergantungan pada volatilitas dolar AS.
  </p>

  <div class="callout" style="background-color: #F7FAFC; border-left-color: #1B365D;">
    <strong>File Output Siap Diunduh:</strong>
    <ul>
      <li>Workbook Excel Lengkap (30 Sheet): <code>output/ASEAN_Inflation_Quarterly_Final.xlsx</code></li>
      <li>Audit Data Sumber Excel: <code>output/Data_Audit.xlsx</code></li>
      <li>Dataset Panel Final CSV: <code>output/ASEAN_Inflation_Quarterly_Final.csv</code></li>
      <li>Log Audit Imputasi Lengkap: <code>output/ASEAN_Imputation_Audit.csv</code></li>
      <li>Log Audit Disaggregasi Temporal: <code>output/ASEAN_Disaggregation_Audit.csv</code></li>
    </ul>
  </div>

</div>
</body>
</html>')

report_path <- "reports/Laporan_Inflasi_ASEAN.html"
writeLines(html_content, report_path)
cat("SUCCESS: Laporan penelitian HTML berhasil dibuat di:", report_path, "\n")
cat(">>> Selesai Tahap 13.\n")

