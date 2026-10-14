# ==============================================================================
# SCRIPT 09: MODEL ESTIMATION & GRANGER CAUSALITY
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vars)
  library(plm)
  library(urca)
})

select <- dplyr::select
filter <- dplyr::filter

cat(">>> Memulai Tahap 9: Estimasi Model Ekonometrika dan Uji Kausalitas Granger...\n")

panel_data <- readRDS("data/processed/panel_final.rds")
panel_final <- panel_data$panel_final %>%
  filter(year >= 2011) %>%
  arrange(country, year, quarter)

regional_asean <- panel_data$regional_asean %>%
  filter(year >= 2011) %>%
  arrange(year, quarter)

# ------------------------------------------------------------------------------
# 1. MODEL UTAMA: ASEAN REGIONAL VARX(2)
# Endogen: inflation_yoy, gdp_growth, money_growth, reer_yoy
# Eksogen (Common Shocks): oil_yoy, fao_yoy, ffr_change
# ------------------------------------------------------------------------------
endo_vars <- c("inflation_yoy", "gdp_growth", "money_growth", "reer_yoy")
exo_vars  <- c("oil_yoy", "fao_yoy", "ffr_change")

y_mat   <- as.matrix(regional_asean[, endo_vars])
exo_mat <- as.matrix(regional_asean[, exo_vars])

var_model <- VAR(y_mat, p = 2, type = "const", exogen = exo_mat)
var_summ <- summary(var_model)

# Ekstrak seluruh koefisien ke dalam dataframe rapi
model_coefs_list <- list()

for (eq_name in endo_vars) {
  eq_res <- var_summ$varresult[[eq_name]]
  c_tab <- as.data.frame(eq_res$coefficients)
  names(c_tab) <- c("estimate", "std_error", "t_stat", "p_value")
  
  c_tab$dependent_var <- eq_name
  c_tab$regressor <- rownames(c_tab)
  c_tab$model_type <- "Regional VARX(2)"
  c_tab$r_squared <- eq_res$r.squared
  c_tab$adj_r_squared <- eq_res$adj.r.squared
  
  model_coefs_list[[eq_name]] <- c_tab
}
var_coefs_df <- bind_rows(model_coefs_list) %>%
  select(model_type, dependent_var, regressor, estimate, std_error, t_stat, p_value, r_squared, adj_r_squared)

# ------------------------------------------------------------------------------
# 2. MODEL PANEL: DYNAMIC PANEL FIXED EFFECTS (PLM)
# Memperhitungkan efek spesifik individual 10 negara ASEAN
# ------------------------------------------------------------------------------
pdata <- pdata.frame(panel_final, index = c("country", "period"))

# Persamaan Dinamika Inflasi Panel
# inflation_yoy ~ lag(inflation_yoy, 1) + lag(gdp_growth, 1) + lag(money_growth, 1) + lag(reer_yoy, 1) + oil_yoy + fao_yoy + ffr_change
panel_fe_mod <- plm(
  inflation_yoy ~ lag(inflation_yoy, 1) + lag(inflation_yoy, 2) +
                  lag(gdp_growth, 1) + lag(money_growth, 1) +
                  lag(reer_yoy, 1) + oil_yoy + fao_yoy + ffr_change,
  data = pdata,
  model = "within",
  effect = "individual"
)
panel_fe_summ <- summary(panel_fe_mod)

panel_coefs_df <- as.data.frame(panel_fe_summ$coefficients)
names(panel_coefs_df) <- c("estimate", "std_error", "t_stat", "p_value")
panel_coefs_df$dependent_var <- "inflation_yoy"
panel_coefs_df$regressor <- rownames(panel_coefs_df)
panel_coefs_df$model_type <- "Panel Fixed Effects (Within 10 Countries)"
panel_coefs_df$r_squared <- as.numeric(panel_fe_summ$r.squared["rsq"])
panel_coefs_df$adj_r_squared <- as.numeric(panel_fe_summ$r.squared["adjrsq"])

# ------------------------------------------------------------------------------
# 3. GABUNGKAN HASIL ESTIMASI
# ------------------------------------------------------------------------------
all_model_results <- bind_rows(var_coefs_df, panel_coefs_df)
dir.create("output", showWarnings = FALSE)
write.csv(all_model_results, "output/ASEAN_Model_Results.csv", row.names = FALSE)

cat("=== KOEFISIEN PERSAMAAN INFLASI REGIONAL VARX(2) ===\n")
print(var_coefs_df %>% filter(dependent_var == "inflation_yoy") %>% select(regressor, estimate, std_error, t_stat, p_value))

cat("\n=== KOEFISIEN PERSAMAAN INFLASI PANEL FIXED EFFECTS ===\n")
print(panel_coefs_df %>% select(regressor, estimate, std_error, t_stat, p_value))

# ------------------------------------------------------------------------------
# 4. UJI KAUSALITAS PREDIKTIF GRANGER (GRANGER CAUSALITY TESTS)
# ------------------------------------------------------------------------------
granger_list <- list()

for (v in endo_vars) {
  gc <- causality(var_model, cause = v)
  granger_list[[length(granger_list) + 1]] <- tibble(
    cause_variable = v,
    test_type = "Granger Causality (Wald F-Test)",
    f_statistic = round(as.numeric(gc$Granger$statistic), 4),
    df1 = as.integer(gc$Granger$parameter["df1"]),
    df2 = as.integer(gc$Granger$parameter["df2"]),
    p_value = round(as.numeric(gc$Granger$p.value), 4),
    conclusion = ifelse(gc$Granger$p.value < 0.05, "Tolak H0: Memiliki Kausalitas Prediktif Signifikan", "Gagal Tolak H0: Tidak Signifikan"),
    instantaneous_p_value = round(as.numeric(gc$Instant$p.value), 4)
  )
}
granger_df <- bind_rows(granger_list)
cat("\n=== HASIL UJI KAUSALITAS GRANGER ===\n")
print(granger_df)

write.csv(granger_df, "output/ASEAN_Granger_Causality.csv", row.names = FALSE)

# Simpan objek model
saveRDS(list(
  var_model = var_model,
  var_summary = var_summ,
  panel_fe_mod = panel_fe_mod,
  panel_fe_summary = panel_fe_summ,
  all_model_results = all_model_results,
  granger_df = granger_df,
  sample_n_obs = nrow(regional_asean),
  panel_n_obs = nrow(panel_final)
), "data/processed/model_estimation.rds")

cat(">>> Selesai Tahap 9. Hasil estimasi model tersimpan di output/ASEAN_Model_Results.csv dan output/ASEAN_Granger_Causality.csv\n")
