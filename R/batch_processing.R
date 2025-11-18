# ==============================================================================
# Title:        Batch Processing
# Description:  Functions for processing multiple PDF files with error handling,
#               retry logic, and progress tracking. Manages batch operations with
#               rate limiting and comprehensive error logging.
# Output:       Combined data frame of results from multiple PDFs
# ==============================================================================

# Configs ----------------------------------------------------------------------

source("config/dependencies.R")
source("config/settings.R")
source("R/extract_metadata.R")

# Helper Functions -------------------------------------------------------------

#' Create error log entry for failed extractions
#'
#' Generates a structured error record with timestamp, filename, error details,
#' and retry attempt number.
#' @param filename Name of the PDF file that failed
#' @param error_message The error message from the failure
#' @param attempt_number Which retry attempt this was (1-based)
#' @return Named list with error details
create_error_log_entry <- function(filename, error_message, attempt_number) {
  list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    filename = filename,
    error_type = class(error_message)[1],
    error_message = as.character(error_message),
    attempt_number = attempt_number
  )
}


#' Extract metadata from single PDF with retry logic
#'
#' Wrapper around extract_pdf_metadata() that implements retry mechanism for
#' transient failures (network timeouts, rate limits, temporary server errors).
#' @param pdf_path Path to PDF file
#' @param fields Metadata fields to extract
#' @param max_attempts Maximum number of retry attempts
#' @return List with success status, result data frame (or NULL), and error log entries
extract_with_retry <- function(pdf_path, fields = DEFAULT_FIELDS, max_attempts = MAX_RETRY_ATTEMPTS) {
  filename <- basename(pdf_path)
  error_log <- list()

  for (attempt in 1:max_attempts) {
    result <- tryCatch({
      # Attempt extraction
      metadata <- extract_pdf_metadata(pdf_path, fields)

      # Success!
      return(list(
        success = TRUE,
        data = metadata,
        error_log = error_log
      ))

    }, error = function(e) {
      # Log this attempt
      error_entry <- create_error_log_entry(filename, e$message, attempt)
      error_log <<- c(error_log, list(error_entry))

      # Determine if we should retry
      error_msg <- tolower(e$message)
      is_retryable <- grepl("timeout|rate limit|network|connection|temporary|503|502|429", error_msg)

      if (is_retryable && attempt < max_attempts) {
        # Calculate exponential backoff delay
        delay <- 2^(attempt - 1) * BATCH_DELAY_SECONDS
        message(paste0("⚠️  Attempt ", attempt, "/", max_attempts, " failed. Retrying in ", delay, " seconds..."))
        Sys.sleep(delay)
        return(NULL)  # Continue to next iteration
      } else {
        # Non-retryable error or max attempts reached
        if (attempt == max_attempts) {
          message(paste0("❌ Failed after ", max_attempts, " attempts: ", filename))
        } else {
          message(paste0("❌ Non-retryable error: ", filename))
        }
        return(list(
          success = FALSE,
          data = NULL,
          error_log = error_log
        ))
      }
    })

    # If we got a result (either success or final failure), return it
    if (!is.null(result)) {
      return(result)
    }
  }

  # Should never reach here, but just in case
  return(list(
    success = FALSE,
    data = NULL,
    error_log = error_log
  ))
}


#' Display progress summary
#'
#' Shows current progress with visual indicators and statistics.
#' @param current Current file number
#' @param total Total number of files
#' @param filename Name of current file
#' @param successful Count of successful extractions so far
#' @param failed Count of failed extractions so far
display_progress <- function(current, total, filename, successful, failed) {
  progress_pct <- round((current - 1) / total * 100)
  message(paste0(
    "\n📊 Progress: ", current, "/", total, " (", progress_pct, "%) | ",
    "✅ ", successful, " successful | ",
    "❌ ", failed, " failed"
  ))
  message(paste0("📄 Processing: ", filename))
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

#' Process multiple PDF files in batch
#'
#' Main batch processing function that orchestrates extraction across multiple
#' files with progress tracking, error handling, and rate limiting.
#' @param pdf_paths Character vector of PDF file paths to process
#' @param fields Character vector of metadata fields to extract (defaults to DEFAULT_FIELDS)
#' @param delay_seconds Delay between API requests for rate limiting (defaults to BATCH_DELAY_SECONDS)
#' @return List with results data frame, error log, and summary statistics
#' @export
process_pdf_batch <- function(pdf_paths,
                               fields = DEFAULT_FIELDS,
                               delay_seconds = BATCH_DELAY_SECONDS) {
  # Validate inputs
  if (length(pdf_paths) == 0) {
    stop("❌ No PDF files provided for processing")
  }

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

    # Extract with retry logic
    extraction_result <- extract_with_retry(pdf_path, fields)

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
#' @param error_log List of error log entries from batch processing
#' @param output_path Path where error log CSV should be saved
#' @return Invisible TRUE if successful
#' @export
save_error_log <- function(error_log, output_path = "error_log.csv") {
  if (length(error_log) == 0) {
    message("ℹ️  No errors to log")
    return(invisible(FALSE))
  }

  # Convert list to data frame
  error_df <- error_log |>
    map_dfr(as_tibble)

  # Write to CSV
  write_csv(error_df, output_path)
  message(paste0("📝 Error log saved to: ", output_path))

  return(invisible(TRUE))
}
