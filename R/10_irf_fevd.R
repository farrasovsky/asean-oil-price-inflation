# ==============================================================================
# SCRIPT 10: IMPULSE RESPONSE FUNCTIONS (IRF) & FEVD
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vars)
  library(ggplot2)
})

select <- dplyr::select
filter <- dplyr::filter

cat(">>> Memulai Tahap 10: Perhitungan IRF dan FEVD...\n")

reg_df <- readRDS("data/processed/panel_final.rds")$regional_asean %>%
  filter(year >= 2011) %>%
  arrange(year, quarter)

# Urutan Cholesky: gdp_growth -> money_growth -> reer_yoy -> inflation_yoy
endo_vars_ordered <- c("gdp_growth", "money_growth", "reer_yoy", "inflation_yoy")
exo_vars  <- c("oil_yoy", "fao_yoy", "ffr_change")

y_mat   <- as.matrix(reg_df[, endo_vars_ordered])
exo_mat <- as.matrix(reg_df[, exo_vars])
# Assign to global environment so bootstrap update can locate them
assign("y_mat", y_mat, envir = .GlobalEnv)
assign("exo_mat", exo_mat, envir = .GlobalEnv)

# Estimasi VAR model terurut
var_ordered <- VAR(y_mat, p = 2, type = "const", exogen = exo_mat)

# ------------------------------------------------------------------------------
# 1. IMPULSE RESPONSE FUNCTIONS (HORIZON = 12 KUARTAL)
# ------------------------------------------------------------------------------
n_horizon <- 12
set.seed(12345)
irf_obj <- irf(var_ordered, response = "inflation_yoy", n.ahead = n_horizon, boot = TRUE, runs = 200, ci = 0.95)

# Ekstrak data IRF numerik
irf_data_list <- list()

for (shock_var in endo_vars_ordered) {
  point_est <- irf_obj$irf[[shock_var]][, "inflation_yoy"]
  lower_ci  <- irf_obj$Lower[[shock_var]][, "inflation_yoy"]
  upper_ci  <- irf_obj$Upper[[shock_var]][, "inflation_yoy"]
  
  irf_data_list[[shock_var]] <- tibble(
    shock_variable = shock_var,
    response_variable = "inflation_yoy",
    horizon = 0:n_horizon,
    irf_point = round(point_est, 4),
    ci_lower_95 = round(lower_ci, 4),
    ci_upper_95 = round(upper_ci, 4),
    identification = "Recursive Cholesky (Order: GDP -> Money -> REER -> Inflation)"
  )
}
irf_df <- bind_rows(irf_data_list)
write.csv(irf_df, "output/ASEAN_IRF_Data.csv", row.names = FALSE)
cat("Data numerik IRF tersimpan di output/ASEAN_IRF_Data.csv\n")

# ------------------------------------------------------------------------------
# 2. FORECAST ERROR VARIANCE DECOMPOSITION (FEVD)
# ------------------------------------------------------------------------------
fevd_obj <- fevd(var_ordered, n.ahead = n_horizon)
fevd_inf <- fevd_obj$inflation_yoy

fevd_df <- as_tibble(fevd_inf) %>%
  mutate(
    horizon = 1:n_horizon,
    response_variable = "inflation_yoy"
  ) %>%
  select(response_variable, horizon, everything())

# Format persentase
fevd_df_pct <- fevd_df %>%
  mutate(across(all_of(endo_vars_ordered), ~ round(.x * 100, 2)))

write.csv(fevd_df_pct, "output/ASEAN_FEVD_Data.csv", row.names = FALSE)
cat("Data numerik FEVD tersimpan di output/ASEAN_FEVD_Data.csv\n")
print(fevd_df_pct)

# ------------------------------------------------------------------------------
# 3. VISUALISASI IRF & FEVD BERKUALITAS TINGGI
# ------------------------------------------------------------------------------
theme_pub <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, color = "#1B365D"),
    plot.subtitle = element_text(size = 9.5, color = "#4A5568", margin = margin(b = 10)),
    plot.caption = element_text(size = 8, color = "#718096", hjust = 0),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#EDF2F7", linewidth = 0.5),
    axis.title = element_text(face = "bold", size = 9.5, color = "#2D3748"),
    strip.background = element_rect(fill = "#E2E8F0", color = NA),
    strip.text = element_text(face = "bold", size = 9, color = "#1A202C")
  )

shock_labels <- c(
  "gdp_growth" = "Shock Pertumbuhan PDB (+1 SD)",
  "money_growth" = "Shock Pertumbuhan Uang Beredar (+1 SD)",
  "reer_yoy" = "Shock Apresiasi REER (+1 SD)",
  "inflation_yoy" = "Shock Inflasi Sendiri (+1 SD)"
)

irf_plot_df <- irf_df %>%
  mutate(shock_label = factor(shock_labels[shock_variable], levels = shock_labels))

p_irf <- ggplot(irf_plot_df, aes(x = horizon, y = irf_point)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lower_95, ymax = ci_upper_95), fill = "#3182CE", alpha = 0.2) +
  geom_line(color = "#2B6CB0", linewidth = 1) +
  geom_point(color = "#2C5282", size = 1.5) +
  facet_wrap(~ shock_label, scales = "free_y", ncol = 2) +
  labs(
    title = "Fungsi Respons Impuls (IRF) Inflasi ASEAN terhadap Shock Makroekonomi",
    subtitle = "Horizon 12 Kuartal (3 Tahun) ke Depan dengan 95% Interval Keyakinan Bootstrap (200 Replikasi)",
    x = "Horizon Kuartal ke Depan (h)", y = "Respons Inflasi YoY (Poin Persentase)",
    caption = "Identifikasi struktural: Dekomposisi Rekursif Cholesky (GDP -> Money -> REER -> Inflasi)."
  ) +
  theme_pub
ggsave("output/figures/08_irf_inflation_responses.png", p_irf, width = 10, height = 7, dpi = 300)

# FEVD Stacked Bar Plot
fevd_long <- fevd_df_pct %>%
  pivot_longer(cols = all_of(endo_vars_ordered), names_to = "shock_source", values_to = "variance_share") %>%
  mutate(shock_source = factor(shock_labels[shock_source], levels = rev(shock_labels)))

p_fevd <- ggplot(fevd_long, aes(x = factor(horizon), y = variance_share, fill = shock_source)) +
  geom_bar(stat = "identity", width = 0.7, color = "white", linewidth = 0.3) +
  scale_fill_manual(
    name = "Sumber Varians Shock:",
    values = c(
      "Shock Inflasi Sendiri (+1 SD)" = "#C53030",
      "Shock Apresiasi REER (+1 SD)" = "#3182CE",
      "Shock Pertumbuhan Uang Beredar (+1 SD)" = "#D69E2E",
      "Shock Pertumbuhan PDB (+1 SD)" = "#38A169"
    )
  ) +
  labs(
    title = "Dekomposisi Varians Kesalahan Prediksi (FEVD) Inflasi ASEAN (1–12 Kuartal)",
    subtitle = "Kontribusi relatif masing-masing shock makro terhadap variasi inflasi regional ASEAN",
    x = "Horizon Prediksi Kuartal (h)", y = "Pangsa Varians (%)",
    caption = "Dekomposisi Cholesky; total kumulatif setiap kuartal = 100%."
  ) +
  theme_pub +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(reverse = TRUE, nrow = 2))
ggsave("output/figures/09_fevd_inflation_stacked.png", p_fevd, width = 9.5, height = 6, dpi = 300)

# Simpan objek R
saveRDS(list(
  var_ordered = var_ordered,
  irf_obj = irf_obj,
  irf_df = irf_df,
  fevd_obj = fevd_obj,
  fevd_df_pct = fevd_df_pct
), "data/processed/irf_fevd_results.rds")

cat(">>> Selesai Tahap 10. Grafik IRF dan FEVD tersimpan di output/figures/\n")
