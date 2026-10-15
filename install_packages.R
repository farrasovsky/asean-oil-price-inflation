# ==============================================================================
# SCRIPT OTOMATIS: INSTALASI DEPENDENCIES & PACKAGES RISET INFLASI ASEAN
# Bahasa: R
# Petunjuk: Cukup jalankan perintah ini di terminal:
#           Rscript install_packages.R
#           Atau jika di RStudio, buka file ini lalu klik 'Source'
# ==============================================================================

cat("\n===============================================================================\n")
cat("      MEMERIKSA DAN MENGINSTAL PACKAGES R UNTUK RISET INFLASI ASEAN           \n")
cat("===============================================================================\n\n")

# Daftar paket R yang dibutuhkan untuk menjalankan seluruh pipeline
required_packages <- c(
  # 1. Manipulasi Data & Pembersihan
  "readxl",       # Membaca data file Excel sumber (.xlsx)
  "dplyr",        # Transformasi dan manipulasi data tabel
  "tidyr",        # Restrukturisasi format data long/wide
  "stringr",      # Pengolahan karakter dan teks string
  "lubridate",    # Manajemen dan konversi tanggal/waktu
  "zoo",          # Operasi data deret waktu dan interpolasi NA
  
  # 2. Visualisasi Grafik Berstandar Publikasi
  "ggplot2",      # Pembuatan grafik publikasi beresolusi tinggi (300 DPI)
  
  # 3. Model Ekonometrika & Uji Statistik
  "plm",          # Estimasi Panel Data (Fixed Effects, Pesaran CD test)
  "vars",         # Estimasi Vector Autoregression (VARX), IRF, FEVD
  "urca",         # Uji Kointegrasi Johansen & Uji Unit Root tingkat lanjut
  "tseries",      # Uji Stasioneritas ADF (Augmented Dickey-Fuller) & KPSS
  
  # 4. Pelaporan
  "knitr"         # Format tabel dan kompilasi laporan
)

cat("Total paket R yang diperlukan:", length(required_packages), "\n\n")

# Periksa paket yang sudah terpasang
installed_pkgs <- rownames(installed.packages())
missing_pkgs <- setdiff(required_packages, installed_pkgs)

if (length(missing_pkgs) == 0) {
  cat("[OK] Semua paket R yang dibutuhkan SUDAH TERPASANG dengan lengkap di komputer Anda!\n")
} else {
  cat(sprintf("[PERHATIAN] Ditemukan %d paket yang belum terpasang:\n", length(missing_pkgs)))
  cat(paste(" -", missing_pkgs, collapse = "\n"), "\n\n")
  cat("Memulai proses instalasi otomatis dari repositori CRAN resmi...\n")
  
  # Gunakan repositori CRAN global yang andal
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  
  for (pkg in missing_pkgs) {
    cat(sprintf("\n>>> Menginstal paket '%s'...\n", pkg))
    tryCatch({
      install.packages(pkg, dependencies = TRUE)
      cat(sprintf("[SUKSES] Paket '%s' berhasil terpasang.\n", pkg))
    }, error = function(e) {
      cat(sprintf("[GAGAL] Gagal menginstal '%s': %s\n", pkg, e$message))
    })
  }
}

# Verifikasi ulang seluruh paket
cat("\n-------------------------------------------------------------------------------\n")
cat("                       HASIL VERIFIKASI INSTALASI                             \n")
cat("-------------------------------------------------------------------------------\n")

all_good <- TRUE
for (pkg in required_packages) {
  is_ok <- requireNamespace(pkg, quietly = TRUE)
  if (is_ok) {
    ver <- as.character(packageVersion(pkg))
    cat(sprintf("[TERPASANG] %-14s (Versi %s)\n", pkg, ver))
  } else {
    cat(sprintf("[MISSING]   %-14s (BELUM TERPASANG)\n", pkg))
    all_good <- FALSE
  }
}

cat("-------------------------------------------------------------------------------\n")
if (all_good) {
  cat("\nSELAMAT! Lingkungan R Anda sudah 100% SIAP menjalankan riset ini.\n")
  cat("Silakan jalankan pipeline utama dengan perintah:\n\n")
  cat("    Rscript run_all.R\n\n")
} else {
  cat("\nMasih ada paket yang belum berhasil terpasang.\n")
  cat("Pastikan komputer Anda terhubung ke internet dan coba jalankan kembali skrip ini.\n\n")
}
cat("===============================================================================\n\n")
