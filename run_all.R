# ==============================================================================
# MASTER RUNNER: PIPELINE RISET DINAMIKA INFLASI NEGARA-NEGARA ASEAN
# Bahasa: R
# Penulis: Tim Ekonometrika & Data Analytics
# ==============================================================================

cat("\n===============================================================================\n")
cat("      MEMULAI MASTER PIPELINE RISET INFLASI ASEAN (R, PANEL VARX, EXCEL)      \n")
cat("===============================================================================\n\n")

start_time <- Sys.time()

scripts <- c(
  "R/01_audit_data.R",
  "R/02_clean_data.R",
  "R/03_quarterly_transformation.R",
  "R/04_imputation.R",
  "R/05_panel_dataset.R",
  "R/06_descriptive_analysis.R",
  "R/07_stationarity_tests.R",
  "R/08_model_selection.R",
  "R/09_model_estimation.R",
  "R/10_irf_fevd.R",
  "R/11_diagnostics.R",
  "R/12_export_excel_csv.R",
  "R/13_generate_report.R",
  "R/14_validation.R"
)

pipeline_log <- list()

for (i in seq_along(scripts)) {
  s <- scripts[i]
  step_title <- sprintf("[%02d/%02d] Menjalankan: %s", i, length(scripts), s)
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  cat(step_title, "\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  t0 <- Sys.time()
  status <- tryCatch({
    source(s)
    "SUCCESS"
  }, error = function(e) {
    cat("ERROR pada skrip:", s, "\nPesan:", e$message, "\n")
    return(paste("FAILED:", e$message))
  })
  t1 <- Sys.time()
  dur <- round(as.numeric(difftime(t1, t0, units = "secs")), 2)
  
  pipeline_log[[length(pipeline_log) + 1]] <- data.frame(
    Step = i,
    Script = s,
    Status = ifelse(grepl("SUCCESS", status), "SUCCESS", "FAILED"),
    Duration_Sec = dur,
    Detail = status,
    stringsAsFactors = FALSE
  )
  
  if (grepl("FAILED", status)) {
    stop("Pipeline berhenti karena error pada tahap: ", s)
  }
}

end_time <- Sys.time()
total_duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)

log_df <- do.call(rbind, pipeline_log)
write.csv(log_df, "output/Pipeline_Execution_Log.csv", row.names = FALSE)

cat("\n===============================================================================\n")
cat("                       RINGKASAN EKSEKUSI MASTER PIPELINE                      \n")
cat("===============================================================================\n")
for (i in 1:nrow(log_df)) {
  cat(sprintf("Step %02d: %-35s [%-7s] (%5.1f detik)\n", 
              log_df$Step[i], log_df$Script[i], log_df$Status[i], log_df$Duration_Sec[i]))
}
cat("===============================================================================\n")
cat(sprintf("Total Waktu Eksekusi: %.2f detik\n", total_duration))
cat("Status Akhir        : SEMUA TAHAP BERHASIL DILAKSANAKAN DENGAN SEMPURNA!\n")
cat("File Utama Tersedia : output/ASEAN_Inflation_Quarterly_Final.xlsx\n")
cat("                      output/ASEAN_Inflation_Quarterly_Final.csv\n")
cat("                      reports/Laporan_Inflasi_ASEAN.html\n")
cat("===============================================================================\n\n")
