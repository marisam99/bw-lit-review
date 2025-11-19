# ==============================================================================
# Title:        Test Summarize Literature Tool
# Description:  Manual integration tests for the literature summary tool.
# Output:       Console messages showing test results
# ==============================================================================

# Setup ------------------------------------------------------------------------

# Load dependencies and functions
source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/build_prompt.R"))
source(here("R/process_response.R"))
source(here("R/api_call_extraction.R"))

# Test 1: Full Extraction (requires .env) --------------------------------------

if (file.exists(here(".env"))) {
  tryCatch({
    result <- extract_pdf_metadata()
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
