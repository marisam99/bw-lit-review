# ==============================================================================
# Title:        Test Batch Processing Functions
# Description:  Manual integration tests for batch PDF processing with error
#               handling, retry logic, and progress tracking. Tests both helper
#               functions and full batch workflow.
# Output:       Console messages showing test results
# ==============================================================================

# Setup ------------------------------------------------------------------------

# Load dependencies and constants
source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/api_call_extraction.R"))
source(here("R/batch_processing.R"))

# Test 1: Error Log Entry Creation --------------------------------------------

tryCatch({
  error_entry <- create_error_log_entry(
    filename = "test.pdf",
    error_message = "Network timeout",
    attempt_number = 2
  )

  # Validate structure
  required_fields <- c("timestamp", "filename", "error_type", "error_message", "attempt_number")
  has_all_fields <- all(required_fields %in% names(error_entry))

  if (has_all_fields) {
    message("✅ Error log entry created successfully")
    message("   Structure:")
    print(str(error_entry))
    message("")
  } else {
    message("❌ Error log entry missing required fields\n")
  }
}, error = function(e) {
  message(paste0("❌ Error log creation failed: ", e$message, "\n"))
})

# Test 2: Progress Display -----------------------------------------------------

tryCatch({
  message("Testing progress display:")
  display_progress(
    current = 3,
    total = 10,
    filename = "sample_paper.pdf",
    successful = 2,
    failed = 0
  )
  message("✅ Progress display working\n")
}, error = function(e) {
  message(paste0("❌ Progress display failed: ", e$message, "\n"))
})

# Test 3: Error Summary Generation ---------------------------------------------

# Create mock error log
mock_errors <- list(
  list(
    timestamp = "2025-11-19 10:15:00",
    filename = "paper1.pdf",
    error_type = "simpleError",
    error_message = "Network timeout",
    attempt_number = 1
  ),
  list(
    timestamp = "2025-11-19 10:15:05",
    filename = "paper1.pdf",
    error_type = "simpleError",
    error_message = "Network timeout",
    attempt_number = 2
  ),
  list(
    timestamp = "2025-11-19 10:20:00",
    filename = "paper2.pdf",
    error_type = "simpleError",
    error_message = "API rate limit exceeded",
    attempt_number = 1
  )
)

tryCatch({
  summary <- generate_error_summary(mock_errors)
  message("✅ Error summary generated successfully")
  message("\nSample error summary:")
  message(summary)
  message("")
}, error = function(e) {
  message(paste0("❌ Error summary generation failed: ", e$message, "\n"))
})

# Test with empty error log
tryCatch({
  summary <- generate_error_summary(list())
  message("✅ Empty error log handled correctly")
  message(paste0("   Result: ", summary, "\n"))
}, error = function(e) {
  message(paste0("❌ Empty error log handling failed: ", e$message, "\n"))
})

# Test 4: Save Error Log -------------------------------------------------------

# Test with mock errors
tryCatch({
  test_output_path <- here("tests", "error_logs", "test_error_log.csv")

  result <- save_error_log(mock_errors, test_output_path)

  if (file.exists(test_output_path)) {
    message("✅ Error log saved successfully")
    message(paste0("   Location: ", test_output_path))

    # Read back and verify
    saved_log <- read_csv(test_output_path, show_col_types = FALSE)
    message(paste0("   Rows saved: ", nrow(saved_log)))
    message(paste0("   Columns: ", paste(names(saved_log), collapse = ", ")))
    message("")
  } else {
    message("❌ Error log file not created\n")
  }
}, error = function(e) {
  message(paste0("❌ Error log saving failed: ", e$message, "\n"))
})

# Test with empty error log
tryCatch({
  result <- save_error_log(list())
  message("✅ Empty error log handled correctly (no file created)\n")
}, error = function(e) {
  message(paste0("❌ Empty error log handling failed: ", e$message, "\n"))
})

# Test 6: Batch Processing (Interactive Test) ---------------------------------

# NOTE: The full batch processing test requires manual file selection."
# To test process_pdf_batch():
#   1. Ensure you have test PDFs available
#   2. Run: result <- process_pdf_batch()
#   3. Select 2-3 test PDF files when prompted
#   4. Review the progress output and final results

result_list <- process_pdf_batch()
results_df <- result_list$results
save_error_log(result_list$error_log)
