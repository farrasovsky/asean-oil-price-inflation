# ==============================================================================
# SCRIPT 02: CLEAN DATA
# Proyek: Riset Dinamika Inflasi ASEAN
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
})

cat(">>> Memulai Tahap 2: Pembersihan dan Standardisasi Data Sumber...\n")

raw_file <- "data/raw/Kebutuhan Data per Variabel Fix (1).xlsx"

# Standardisasi nama negara
standardize_country <- function(c) {
  c <- str_trim(c)
  case_when(
    c %in% c("Philipines", "Philippines") ~ "Philippines",
    c %in% c("Laos (Lao PDR)", "Laos", "Lao PDR") ~ "Laos",
    c %in% c("Brunei Darussalam", "Brunei") ~ "Brunei",
    TRUE ~ c
  )
}

# 1. PEMBERSIHAN HCPI (INFLASI)
inf_raw <- read_excel(raw_file, sheet = "Inflasi Cleaned (kurang", col_names = FALSE)
dates_raw <- as.character(unlist(inf_raw[2, 2:ncol(inf_raw)]))

# Perbaiki header col 184 (yang bernilai NA tetapi posisinya setelah 202502)
if (is.na(dates_raw[length(dates_raw)])) {
  dates_raw[length(dates_raw)] <- "202503"
}

countries_raw <- as.character(unlist(inf_raw[3:nrow(inf_raw), 1]))
inf_matrix <- as.matrix(inf_raw[3:nrow(inf_raw), 2:ncol(inf_raw)])
class(inf_matrix) <- "numeric"

df_hcpi_long <- tibble()
for (i in seq_along(countries_raw)) {
  c_name <- countries_raw[i]
  vals <- inf_matrix[i, ]
  tmp <- tibble(
    country_raw = c_name,
    country = standardize_country(c_name),
    period_str = dates_raw,
    year = as.integer(substr(dates_raw, 1, 4)),
    month = as.integer(substr(dates_raw, 5, 6)),
    hcpi = vals
  )
  df_hcpi_long <- bind_rows(df_hcpi_long, tmp)
}
df_hcpi_long <- df_hcpi_long %>%
  mutate(quarter = (month - 1) %/% 3 + 1,
         period = sprintf("%d Q%d", year, quarter))

cat("HCPI long selesai:", nrow(df_hcpi_long), "baris | Rentang:", min(df_hcpi_long$period_str), "s.d.", max(df_hcpi_long$period_str), "\n")

# 2. PEMBERSIHAN PDB TAHUNAN
pdb_raw <- read_excel(raw_file, sheet = "PDB")
year_cols_pdb <- setdiff(names(pdb_raw), "Negara")

df_pdb_long <- pdb_raw %>%
  pivot_longer(cols = all_of(year_cols_pdb), names_to = "year_str", values_to = "gdp_growth") %>%
  mutate(
    country_raw = Negara,
    country = standardize_country(Negara),
    year = as.integer(year_str),
    gdp_growth = as.numeric(gdp_growth)
  ) %>%
  select(country_raw, country, year, gdp_growth)

cat("PDB long selesai:", nrow(df_pdb_long), "baris | Tahun:", min(df_pdb_long$year), "s.d.", max(df_pdb_long$year), "\n")

# 3. PEMBERSIHAN MONEY GROWTH TAHUNAN
mg_raw <- read_excel(raw_file, sheet = "Money Growth (kurang)")
year_cols_mg <- setdiff(names(mg_raw), "Negara")

df_mg_long <- mg_raw %>%
  pivot_longer(cols = all_of(year_cols_mg), names_to = "year_str", values_to = "money_growth") %>%
  mutate(
    country_raw = Negara,
    country = standardize_country(Negara),
    year = as.integer(year_str),
    money_growth = as.numeric(money_growth)
  ) %>%
  select(country_raw, country, year, money_growth)

cat("Money Growth long selesai:", nrow(df_mg_long), "baris | Tahun:", min(df_mg_long$year), "s.d.", max(df_mg_long$year), "\n")

# 4. PEMBERSIHAN REER BULANAN
reer_raw <- read_excel(raw_file, sheet = "REER Cleaned (kurang)")
country_cols_reer <- setdiff(names(reer_raw), "Month")

df_reer_long <- reer_raw %>%
  pivot_longer(cols = all_of(country_cols_reer), names_to = "country_raw", values_to = "reer") %>%
  mutate(
    country = standardize_country(country_raw),
    year = as.integer(substr(Month, 1, 4)),
    month = as.integer(substr(Month, 6, 7)),
    quarter = (month - 1) %/% 3 + 1,
    period = sprintf("%d Q%d", year, quarter),
    reer = as.numeric(reer)
  ) %>%
  select(country_raw, country, Month, year, month, quarter, period, reer)

cat("REER long selesai:", nrow(df_reer_long), "baris | Bulan:", min(df_reer_long$Month), "s.d.", max(df_reer_long$Month), "\n")

# 5. PEMBERSIHAN FAO FOOD PRICE INDEX BULANAN
fao_raw <- read_excel(raw_file, sheet = "FAO Cleaned")
names(fao_raw) <- c("date", "fao_index")
df_fao_clean <- fao_raw %>%
  mutate(
    date = as.Date(date),
    year = as.integer(year(date)),
    month = as.integer(month(date)),
    quarter = (month - 1) %/% 3 + 1,
    period = sprintf("%d Q%d", year, quarter),
    fao_index = as.numeric(fao_index)
  )

cat("FAO clean selesai:", nrow(df_fao_clean), "baris\n")

# 6. PEMBERSIHAN FEDERAL FUNDS RATE (FFR) BULANAN
ffr_raw <- read_excel(raw_file, sheet = "Federal Funds Rate Cleaned")
names(ffr_raw) <- c("date", "ffr")
df_ffr_clean <- ffr_raw %>%
  mutate(
    date = as.Date(date),
    year = as.integer(year(date)),
    month = as.integer(month(date)),
    quarter = (month - 1) %/% 3 + 1,
    period = sprintf("%d Q%d", year, quarter),
    ffr = as.numeric(ffr)
  )

cat("FFR clean selesai:", nrow(df_ffr_clean), "baris\n")

# 7. PEMBERSIHAN HARGA MINYAK MENTAH BULANAN
oil_raw <- read_excel(raw_file, sheet = "Oil")
names(oil_raw) <- c("date", "oil_price")
df_oil_clean <- oil_raw %>%
  mutate(
    date = as.Date(date),
    year = as.integer(year(date)),
    month = as.integer(month(date)),
    quarter = (month - 1) %/% 3 + 1,
    period = sprintf("%d Q%d", year, quarter),
    oil_price = as.numeric(oil_price)
  )

cat("Oil clean selesai:", nrow(df_oil_clean), "baris\n")

# Simpan semua tabel bersih
saveRDS(list(
  hcpi_monthly = df_hcpi_long,
  gdp_annual = df_pdb_long,
  money_annual = df_mg_long,
  reer_monthly = df_reer_long,
  fao_monthly = df_fao_clean,
  ffr_monthly = df_ffr_clean,
  oil_monthly = df_oil_clean
), "data/processed/clean_raw_tables.rds")

cat(">>> Selesai Tahap 2. Seluruh tabel tersimpan di data/processed/clean_raw_tables.rds\n")

