# ==============================================================================
# Title:        Summarize Literature
# Description:  Sends requested PDF files to the OpenAI API to extract
#               bibliographic metadata and key findings.
# Output:       Data frame with one row per PDF containing extracted metadata,
#               and optional error log CSV if any failures occurred
# ==============================================================================

# Configs ----------------------------------------------------------------------

source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/build_prompt.R"))
source(here("R/process_response.R"))
source(here("R/api_call_extraction.R"))
source(here("R/batch_processing.R"))

# Run Tool ---------------------------------------------------------------------

# Process PDF files (opens file picker - can select 1 or more files)
result_list <- process_pdf_batch()

# Extract results
results <- result_list$results

# Save error log if there were any failures
if (result_list$summary$failed > 0) {
  save_error_log(result_list$error_log)
}

# Display results summary
message("\n📊 Results Summary:")
message(paste0("   Total rows: ", nrow(results)))
if (nrow(results) > 0) {
  message(paste0("   Columns: ", paste(names(results), collapse = ", ")))
}

# Optionally save results to CSV
# Uncomment the following lines to automatically save results:
# output_file <- here("output", paste0(OUTPUT_FILENAME_PREFIX, "_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
# write_csv(results, output_file)
# message(paste0("\n💾 Results saved to: ", output_file))