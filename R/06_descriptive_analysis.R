# ==============================================================================
# SCRIPT 06: DESCRIPTIVE ANALYSIS & VISUALIZATION
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(stringr)
})

cat(">>> Memulai Tahap 6: Analisis Deskriptif dan Visualisasi Data...\n")

panel_data <- readRDS("data/processed/panel_final.rds")
panel_final <- panel_data$panel_final
panel_raw   <- panel_data$panel_raw
regional_asean <- panel_data$regional_asean

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. TABEL STATISTIK DESKRIPTIF PER NEGARA DAN REGIONAL
# ------------------------------------------------------------------------------
vars_to_summarise <- c("inflation_yoy", "inflation_qoq", "gdp_growth", "money_growth", "reer_yoy", "hcpi_q", "reer_q")

calc_stats <- function(df, group_col = "country") {
  res_list <- list()
  groups <- unique(df[[group_col]])
  
  for (g in groups) {
    sub_df <- df[df[[group_col]] == g, ]
    for (v in vars_to_summarise) {
      vals <- sub_df[[v]]
      vals_no_na <- vals[!is.na(vals)]
      
      n_total <- length(vals)
      n_valid <- length(vals_no_na)
      n_missing <- sum(is.na(vals))
      
      if (n_valid > 0) {
        m_val   <- mean(vals_no_na)
        med_val <- median(vals_no_na)
        sd_val  <- sd(vals_no_na)
        min_val <- min(vals_no_na)
        max_val <- max(vals_no_na)
        
        # Skewness & Kurtosis
        m3 <- sum((vals_no_na - m_val)^3) / n_valid
        m2 <- sum((vals_no_na - m_val)^2) / n_valid
        m4 <- sum((vals_no_na - m_val)^4) / n_valid
        skew_val <- if (m2 > 0) m3 / (m2^(1.5)) else 0
        kurt_val <- if (m2 > 0) (m4 / (m2^2)) - 3 else 0
      } else {
        m_val <- med_val <- sd_val <- min_val <- max_val <- skew_val <- kurt_val <- NA_real_
      }
      
      res_list[[length(res_list) + 1]] <- tibble(
        entity = as.character(g),
        variable = v,
        n_obs = n_valid,
        n_missing = n_missing,
        mean = round(m_val, 3),
        sd = round(sd_val, 3),
        median = round(med_val, 3),
        min = round(min_val, 3),
        max = round(max_val, 3),
        skewness = round(skew_val, 3),
        kurtosis = round(kurt_val, 3)
      )
    }
  }
  bind_rows(res_list)
}

desc_stats_country <- calc_stats(panel_final, "country")

# Deskriptif variabel regional & global
global_vars <- c("fao_q", "fao_yoy", "ffr_q", "ffr_change", "oil_q", "oil_yoy")
global_stats_list <- list()
for (gv in global_vars) {
  vals <- regional_asean[[gv]]
  vals_no_na <- vals[!is.na(vals)]
  n_valid <- length(vals_no_na)
  m_val <- mean(vals_no_na)
  med_val <- median(vals_no_na)
  sd_val <- sd(vals_no_na)
  min_val <- min(vals_no_na)
  max_val <- max(vals_no_na)
  m3 <- sum((vals_no_na - m_val)^3) / n_valid
  m2 <- sum((vals_no_na - m_val)^2) / n_valid
  m4 <- sum((vals_no_na - m_val)^4) / n_valid
  skew_val <- m3 / (m2^(1.5))
  kurt_val <- (m4 / (m2^2)) - 3
  
  global_stats_list[[length(global_stats_list) + 1]] <- tibble(
    entity = "Global/External",
    variable = gv,
    n_obs = n_valid,
    n_missing = sum(is.na(vals)),
    mean = round(m_val, 3),
    sd = round(sd_val, 3),
    median = round(med_val, 3),
    min = round(min_val, 3),
    max = round(max_val, 3),
    skewness = round(skew_val, 3),
    kurtosis = round(kurt_val, 3)
  )
}
global_desc_stats <- bind_rows(global_stats_list)

all_desc_stats <- bind_rows(desc_stats_country, global_desc_stats)
write.csv(all_desc_stats, "output/ASEAN_Descriptive_Statistics.csv", row.names = FALSE)
cat("Tabel statistik deskriptif tersimpan di output/ASEAN_Descriptive_Statistics.csv\n")

# ------------------------------------------------------------------------------
# 2. PEMBUATAN VISUALISASI BERSTANDAR PUBLIKASI (GGPLOT2)
# ------------------------------------------------------------------------------
theme_pub <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13, color = "#1B365D"),
    plot.subtitle = element_text(size = 10, color = "#4A5568", margin = margin(b = 10)),
    plot.caption = element_text(size = 8, color = "#718096", hjust = 0, margin = margin(t = 10)),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#EDF2F7", linewidth = 0.5),
    axis.title = element_text(face = "bold", size = 10, color = "#2D3748"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 9),
    strip.background = element_rect(fill = "#E2E8F0", color = NA),
    strip.text = element_text(face = "bold", size = 9, color = "#1A202C")
  )

# Tambahkan time_index untuk plotting yang rapi
panel_final <- panel_final %>%
  mutate(time_idx = year + (quarter - 1)/4)
regional_asean <- regional_asean %>%
  mutate(time_idx = year + (quarter - 1)/4)

# G1: Inflasi YoY Faceted per Negara
p1 <- ggplot(panel_final %>% filter(!is.na(inflation_yoy)), aes(x = time_idx, y = inflation_yoy)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(color = "#C53030", linewidth = 0.8) +
  geom_point(data = panel_final %>% filter(imputation_count > 0, !is.na(inflation_yoy)),
             color = "#DD6B20", size = 1.2, shape = 17) +
  facet_wrap(~ country, scales = "free_y", ncol = 5) +
  labs(
    title = "Dinamika Inflasi Tahunan (YoY) di 10 Negara ASEAN (2011–2025)",
    subtitle = "Tingkat inflasi berbasis indeks HCPI kuartalan. Segitiga oranye menandai observasi hasil estimasi/imputasi.",
    x = "Tahun", y = "Inflasi YoY (%)",
    caption = "Sumber data: Workbook Sumber diolah; Garis merah = Inflasi aktual/terimputasi."
  ) +
  theme_pub
ggsave("output/figures/01_inflation_yoy_by_country.png", p1, width = 12, height = 6.5, dpi = 300)

# G2: Perbandingan Inflasi Antarnegara (Multi-line)
p2 <- ggplot(panel_final %>% filter(!is.na(inflation_yoy)), aes(x = time_idx, y = inflation_yoy, color = country)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_line(linewidth = 0.75, alpha = 0.85) +
  scale_color_brewer(palette = "Paired", name = "Negara ASEAN:") +
  labs(
    title = "Perbandingan Lintasan Inflasi Antarnegara ASEAN (2011–2025)",
    subtitle = "Menampilkan heterogenitas tekanan inflasi dan spike ekstrem di Laos dan Myanmar pasca-2021",
    x = "Tahun", y = "Inflasi YoY (%)",
    caption = "Catatan: Lonjakan inflasi tinggi terlihat di Laos dan Myanmar akibat depresiasi mata uang domestik."
  ) +
  theme_pub +
  guides(color = guide_legend(nrow = 2))
ggsave("output/figures/02_inflation_comparison_multicountry.png", p2, width = 10, height = 5.5, dpi = 300)

# G3: Inflasi Agregat ASEAN vs External Drivers (Minyak, FAO, FFR)
p3 <- ggplot(regional_asean %>% filter(!is.na(inflation_yoy)), aes(x = time_idx)) +
  geom_line(aes(y = inflation_yoy, color = "Inflasi Rata-rata ASEAN (%)"), linewidth = 1.1) +
  geom_line(aes(y = oil_yoy / 5, color = "Harga Minyak Dunia (YoY/5)"), linewidth = 0.8, linetype = "twodash") +
  geom_line(aes(y = fao_yoy / 5, color = "Indeks Pangan FAO (YoY/5)"), linewidth = 0.8, linetype = "dotted") +
  geom_line(aes(y = ffr_q, color = "Federal Funds Rate (%)"), linewidth = 0.8) +
  scale_color_manual(
    name = "Variabel Makro:",
    values = c(
      "Inflasi Rata-rata ASEAN (%)" = "#C53030",
      "Harga Minyak Dunia (YoY/5)" = "#2B6CB0",
      "Indeks Pangan FAO (YoY/5)" = "#38A169",
      "Federal Funds Rate (%)" = "#805AD5"
    )
  ) +
  labs(
    title = "Ko-pergerakan Inflasi Agregat ASEAN dengan Shock Global (2011–2025)",
    subtitle = "Perbandingan tren inflasi rata-rata kawasan dengan komoditas global dan suku bunga AS",
    x = "Tahun", y = "Tingkat (%) / Skala Terstandarisasi",
    caption = "Catatan: YoY Minyak dan FAO diskalakan (/5) untuk perbandingan visual dinamika bersama."
  ) +
  theme_pub
ggsave("output/figures/03_asean_inflation_vs_global_drivers.png", p3, width = 10, height = 5.5, dpi = 300)

# G4: Pertumbuhan PDB dan Money Growth Faceted
p4 <- ggplot(panel_final %>% filter(!is.na(gdp_growth)), aes(x = time_idx)) +
  geom_line(aes(y = gdp_growth, color = "Pertumbuhan PDB (%)"), linewidth = 0.8) +
  geom_line(aes(y = money_growth, color = "Money Growth (%)"), linewidth = 0.7, linetype = "dashed") +
  facet_wrap(~ country, scales = "free_y", ncol = 5) +
  scale_color_manual(
    name = "Variabel:",
    values = c("Pertumbuhan PDB (%)" = "#2B6CB0", "Money Growth (%)" = "#D69E2E")
  ) +
  labs(
    title = "Pertumbuhan PDB dan Money Growth Kuartalan di Kawasan ASEAN (2010–2025)",
    subtitle = "Hasil disaggregasi temporal kuartalan (Denton-Cholette) mempertahankan benchmark tahunan",
    x = "Tahun", y = "Tingkat Pertumbuhan (%)",
    caption = "Sumber: Data PDB dan Money Growth tahunan di-disaggregasi secara kuadratik."
  ) +
  theme_pub
ggsave("output/figures/04_gdp_and_money_growth.png", p4, width = 12, height = 6.5, dpi = 300)

# G5: REER, FAO, FFR, dan Oil Trends
p5_reer <- ggplot(panel_final, aes(x = time_idx, y = reer_q, color = country)) +
  geom_line(linewidth = 0.7) +
  scale_color_brewer(palette = "Paired", name = "Negara:") +
  labs(
    title = "Dinamika Real Effective Exchange Rate (REER) ASEAN (2010–2025)",
    subtitle = "Indeks REER kuartalan (100 = periode dasar)",
    x = "Tahun", y = "Indeks REER",
    caption = "Sumber: Sheet REER Cleaned diolah."
  ) +
  theme_pub +
  guides(color = guide_legend(nrow = 2))
ggsave("output/figures/05_reer_trends_all_countries.png", p5_reer, width = 10, height = 5.5, dpi = 300)

# G6: Matriks Korelasi Inflasi Antarnegara
cor_mat_data <- panel_final %>%
  select(country, period, inflation_yoy) %>%
  filter(!is.na(inflation_yoy)) %>%
  pivot_wider(names_from = country, values_from = inflation_yoy) %>%
  select(-period)
cor_mat <- cor(cor_mat_data, use = "pairwise.complete.obs")
cor_df <- as.data.frame(as.table(cor_mat))
names(cor_df) <- c("Country_A", "Country_B", "Correlation")

p6 <- ggplot(cor_df, aes(x = Country_A, y = Country_B, fill = Correlation)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", Correlation)), size = 3, color = ifelse(abs(cor_df$Correlation) > 0.6, "white", "black")) +
  scale_fill_gradient2(low = "#2B6CB0", mid = "#FFFFFF", high = "#C53030", midpoint = 0, limits = c(-1, 1), name = "Korelasi:") +
  labs(
    title = "Matriks Korelasi Inflasi YoY Antarnegara ASEAN (2011–2025)",
    subtitle = "Menunjukkan derajat sinkronisasi siklus inflasi lintas batas negara di Asia Tenggara",
    x = "", y = ""
  ) +
  theme_pub +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("output/figures/06_cross_country_inflation_correlation.png", p6, width = 8, height = 6.5, dpi = 300)

# G7: Ringkasan Status Kualitas Data & Imputasi
p7 <- ggplot(panel_final, aes(x = period, y = country, fill = data_quality_flag)) +
  geom_tile(color = "grey90", linewidth = 0.2) +
  scale_fill_manual(
    name = "Klasifikasi Kualitas Data:",
    values = c(
      "High_Quality_Observed" = "#48BB78",
      "Baseline_Lag_Origin" = "#A0AEC0",
      "Minor_Imputation_1Var" = "#ECC94B",
      "Major_Imputation_MultiVar" = "#ED8936"
    )
  ) +
  labs(
    title = "Peta Audit Kualitas Data dan Tingkat Imputasi Panel ASEAN (2010–2025)",
    subtitle = "Transparansi asal data per kuartal: hijau = observasi murni; kuning/oranye = terimputasi",
    x = "Periode Kuartalan", y = "Negara",
    caption = "Catatan: Abu-abu (2010) = periode awal untuk lag HCPI; Oranye = beberapa variabel terimputasi (Laos, Myanmar)."
  ) +
  theme_pub +
  theme(
    axis.text.x = element_text(angle = 90, size = 6, vjust = 0.5),
    legend.position = "bottom"
  )
ggsave("output/figures/07_data_quality_imputation_heatmap.png", p7, width = 12, height = 5.5, dpi = 300)

cat(">>> Selesai Tahap 6. Seluruh visualisasi tersimpan di output/figures/\n")

