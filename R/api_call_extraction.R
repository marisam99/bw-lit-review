# ==============================================================================
# Title:        Summarize Literature
# Description:  Sends requested PDF files to the OpenAI API to extract 
#               bibliographic metadata and key findings.
# Output:       Data frame with one row per PDF containing extracted metadata
# ==============================================================================

# Configs ----------------------------------------------------------------------

source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/build_prompt.R"))
source(here("R/process_response.R"))

# Helper Functions -------------------------------------------------------------

#' Create error log entry for failed extractions
#'
#' Generates a structured error record with timestamp, filename, error details,
#' and retry attempt number. Handles special error types (httr2, rlang) robustly.
#' @param filename Name of the PDF file that failed
#' @param error_obj The error object from the failure
#' @param attempt_number Which retry attempt this was (1-based)
#' @return Named list with error details
create_error_log_entry <- function(filename, error_obj, attempt_number) {
  # Extract error message safely
  error_msg <- tryCatch({
    if (inherits(error_obj, "httr2_error")) {
      # For httr2 errors, get the message more carefully
      conditionMessage(error_obj)
    } else if (is.character(error_obj)) {
      error_obj
    } else {
      as.character(error_obj)
    }
  }, error = function(e) {
    # Fallback if even getting the message fails
    paste("Error extracting error message:", class(error_obj)[1])
  })

  list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    filename = filename,
    error_type = class(error_obj)[1],
    error_message = error_msg,
    attempt_number = attempt_number
  )
}

# Main Functions ---------------------------------------------------------------

#' Extract metadata from a single PDF file with automatic retry
#'
#' Main extraction function that orchestrates the entire process: validates file,
#' loads API key, uploads PDF to OpenAI, sends extraction request, and returns
#' parsed metadata. Includes automatic retry logic with exponential backoff for
#' transient failures (network timeouts, rate limits, temporary server errors).
#' @param pdf_path Path to PDF file to process. If NULL, opens file chooser dialog.
#' @param fields Character vector of metadata fields to extract (defaults to DEFAULT_FIELDS)
#' @param max_attempts Maximum number of retry attempts for transient failures (defaults to MAX_RETRY_ATTEMPTS)
#' @return List with success status, result data frame (or NULL), and error log entries
#' @export
extract_pdf_metadata <- function(pdf_path = NULL, fields = DEFAULT_FIELDS, max_attempts = MAX_RETRY_ATTEMPTS) {
  # If no path provided, use file chooser
  if (is.null(pdf_path)) {
    pdf_path <- file.choose()
  }

  # Validate PDF file
  validate_pdf_file(pdf_path)

  # Load and validate API key
  api_key <- load_api_key()

  # Build extraction prompt
  prompt <- build_extraction_prompt(fields)

  # Extract just the filename for display
  filename <- basename(pdf_path)
  error_log <- list()

  # Retry loop for transient failures
  for (attempt in 1:max_attempts) {
    result <- tryCatch({
      # Make API request using ellmer
      chat <- chat_openai(
        model = OPENAI_MODEL,
        api_key = api_key,
        system_prompt = SYSTEM_PROMPT,
        api_args = list(
          reasoning_effort = REASONING_EFFORT,
          verbosity = VERBOSITY
        ),
        echo = "none"  # Suppress console output
      )

      # Upload PDF and send request
      response <- chat$chat(
        content_pdf_file(pdf_path),
        prompt
      )

      # Parse response
      metadata <- parse_extraction_response(response, expected_fields = fields)

      # Add filename to results
      metadata <- metadata |>
        mutate(filename = filename, .before = 1)

      message(paste0("✅ Completed: ", filename, "\n"))

      # Success!
      return(list(
        success = TRUE,
        data = metadata,
        error_log = error_log
      ))

    }, error = function(e) {
      # Log this attempt
      error_entry <- create_error_log_entry(filename, e, attempt)
      error_log <<- c(error_log, list(error_entry))

      # Determine if we should retry
      error_msg <- tolower(conditionMessage(e))
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
