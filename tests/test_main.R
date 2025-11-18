# ==============================================================================
# Title:        Test Summarize Literature Tool
# Description:  Manual integration tests for the literature summary tool.
# Output:       Console messages showing test results
# ==============================================================================

# Setup ------------------------------------------------------------------------

# Load dependencies and functions
source(here("R/MAIN_summarize_literature.R"))

# Test 1: Full Extraction (requires .env) --------------------------------------

if (file.exists(here(".env"))) {
  tryCatch({
    result <- extract_pdf_metadata(test_file)
    message("✅ Full extraction successful")
    message("\nExtracted metadata:")
    print(result)
    message("")
  }, error = function(e) {
    message(paste0("❌ Extraction failed: ", e$message, "\n"))
  })
} else {
  message("⚠️  Skipping full extraction test - .env file not found")
}
