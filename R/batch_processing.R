# ==============================================================================
# Title:        Batch Processing
# Description:  Functions for processing multiple PDF files with error handling,
#               retry logic, and progress tracking. Manages batch operations with
#               rate limiting and comprehensive error logging.
# Output:       Combined data frame of results from multiple PDFs
#
# Usage:
#   # Always opens file picker - select 1 or more PDFs
#   result_list <- process_pdf_batch()
#   results_df <- result_list$results
#
#   # Optionally save error log if there were failures
#   save_error_log(result_list$error_log)
# ==============================================================================

# Configs ----------------------------------------------------------------------

source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/api_call_extraction.R"))

# Helper Functions -------------------------------------------------------------

#' Display progress summary
#'
#' Shows current progress with visual indicators and statistics.
#' @param current Current file number
#' @param total Total number of files
#' @param filename Name of current file
#' @param successful Count of successful extractions so far
#' @param failed Count of failed extractions so far
display_progress <- function(current, total, filename, successful, failed) {
  message(paste0(
    "\n📊 Progress: ",
    "✅ ", successful, " successful | ",
    "❌ ", failed, " failed"
  ))
  message(paste0("📄 Processing: ", filename, " (", current, "/", total, ")"))
}


#' Generate error summary report
#'
#' Creates a human-readable summary of all errors encountered during batch processing.
#' @param error_log List of error log entries
#' @return Character string with formatted error summary
generate_error_summary <- function(error_log) {
  if (length(error_log) == 0) {
    return("No errors encountered. ✨")
  }

  # Count errors by filename
  error_counts <- error_log |>
    map_chr("filename") |>
    table()

  summary_lines <- c(
    paste0("\n❌ Error Summary (", length(error_log), " total errors):"),
    "\nFailed files:"
  )

  for (filename in names(error_counts)) {
    count <- error_counts[[filename]]
    # Get last error message for this file
    last_error <- error_log |>
      keep(~ .x$filename == filename) |>
      tail(1) |>
      pluck(1, "error_message")

    summary_lines <- c(
      summary_lines,
      paste0("  - ", filename, " (", count, " attempts): ", last_error)
    )
  }

  return(paste(summary_lines, collapse = "\n"))
}

# Main Functions ---------------------------------------------------------------

#' Process PDF files in batch with interactive file picker
#'
#' Opens a file picker to select one or more PDF files, then processes them with
#' progress tracking, error handling, and retry logic. Works whether you select
#' a single file or multiple files.
#' @param fields Character vector of metadata fields to extract (defaults to DEFAULT_FIELDS)
#' @param delay_seconds Delay between API requests for rate limiting (defaults to BATCH_DELAY_SECONDS)
#' @return List with results data frame, error log, and summary statistics
#' @export
process_pdf_batch <- function(fields = DEFAULT_FIELDS,
                               delay_seconds = BATCH_DELAY_SECONDS) {
  # Always open file picker
  message("📂 Opening file picker... (Select one or more PDF files)")

  # Try using tcltk for cross-platform multi-file selection
  pdf_paths <- tryCatch({
    tcltk::tk_choose.files(
      default = "",
      caption = "Select PDF files to process",
      multi = TRUE,
      filters = matrix(c("PDF files", ".pdf", "All files", "*"), 2, 2, byrow = TRUE)
    )
  }, error = function(e) {
    # Fallback to base file.choose() if tcltk not available
    warning("⚠️  Multi-file picker not available. Please select files one at a time (press Cancel when done).")
    selected_files <- character()
    repeat {
      tryCatch({
        file_path <- file.choose()
        selected_files <- c(selected_files, file_path)
        message(paste0("✓ Selected: ", basename(file_path), " (", length(selected_files), " files total)"))
      }, error = function(e) {
        # User cancelled, we're done
        break
      })
    }
    return(selected_files)
  })

  # Check if user cancelled without selecting files
  if (length(pdf_paths) == 0) {
    stop("❌ No files selected. Batch processing cancelled.")
  }

  message(paste0("✅ Selected ", length(pdf_paths), " file(s) for processing\n"))

  # Initialize tracking variables
  total_files <- length(pdf_paths)
  successful_results <- list()
  all_error_logs <- list()
  successful_count <- 0
  failed_count <- 0
  start_time <- Sys.time()

  # Display initial message
  message(paste0("\n", strrep("=", 70)))
  message(paste0("🚀 Starting batch processing of ", total_files, " PDF files"))
  message(paste0(strrep("=", 70)))

  # Process each file
  for (i in seq_along(pdf_paths)) {
    pdf_path <- pdf_paths[i]
    filename <- basename(pdf_path)

    # Display progress
    display_progress(i, total_files, filename, successful_count, failed_count)

    # Validate file exists before attempting extraction
    if (!file.exists(pdf_path)) {
      message(paste0("❌ File not found, skipping: ", filename, "\n"))
      failed_count <- failed_count + 1
      error_entry <- create_error_log_entry(filename, "File not found", 1)
      all_error_logs <- c(all_error_logs, list(error_entry))
      next
    }

    # Extract metadata (includes automatic retry logic)
    extraction_result <- extract_pdf_metadata(pdf_path, fields)

    # Process result
    if (extraction_result$success) {
      successful_results <- c(successful_results, list(extraction_result$data))
      successful_count <- successful_count + 1
    } else {
      failed_count <- failed_count + 1
    }

    # Add error logs from this extraction
    all_error_logs <- c(all_error_logs, extraction_result$error_log)

    # Rate limiting delay (except after last file)
    if (i < total_files) {
      Sys.sleep(delay_seconds)
    }
  }

  # Combine successful results
  if (length(successful_results) > 0) {
    combined_results <- bind_rows(successful_results)
  } else {
    # Create empty data frame with expected columns
    combined_results <- tibble(filename = character()) |>
      bind_cols(
        map(fields, ~ tibble(!!.x := character())) |>
          bind_cols()
      )
  }

  # Calculate timing
  end_time <- Sys.time()
  elapsed_time <- difftime(end_time, start_time, units = "secs")

  # Display final summary
  message(paste0("\n", strrep("=", 70)))
  message("📋 Batch Processing Complete!")
  message(paste0(strrep("=", 70)))
  message(paste0("✅ Successful: ", successful_count, "/", total_files))
  message(paste0("❌ Failed: ", failed_count, "/", total_files))
  message(paste0("⏱️  Total time: ", round(elapsed_time, 1), " seconds"))
  message(paste0("⚡ Average time per file: ", round(elapsed_time / total_files, 1), " seconds"))

  # Display error summary if there were failures
  if (failed_count > 0) {
    message(generate_error_summary(all_error_logs))
  }

  message(paste0(strrep("=", 70), "\n"))

  # Return comprehensive results
  return(list(
    results = combined_results,
    error_log = all_error_logs,
    summary = list(
      total_files = total_files,
      successful = successful_count,
      failed = failed_count,
      elapsed_seconds = as.numeric(elapsed_time)
    )
  ))
}


#' Save error log to file
#'
#' Writes error log entries to a CSV file for later review.
#' Saves to tests/error_logs directory by default.
#' @param error_log List of error log entries from batch processing
#' @param output_path Path where error log CSV should be saved (defaults to tests/error_logs)
#' @return Invisible TRUE if successful
#' @export
save_error_log <- function(error_log, output_path = NULL) {
  if (length(error_log) == 0) {
    message("ℹ️  No errors to log")
    return(invisible(FALSE))
  }

  # If no path specified, save to tests/error_logs with timestamp
  if (is.null(output_path)) {
    # Create error_logs directory if it doesn't exist
    error_log_dir <- here("tests", "error_logs")
    if (!dir.exists(error_log_dir)) {
      dir.create(error_log_dir, recursive = TRUE)
    }

    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_path <- here("tests", "error_logs", paste0("error_log_", timestamp, ".csv"))
  }

  # Convert list to data frame
  error_df <- error_log |>
    map_dfr(as_tibble)

  # Write to CSV
  write_csv(error_df, output_path)
  message(paste0("📝 Error log saved to: ", output_path))

  return(invisible(TRUE))
}
