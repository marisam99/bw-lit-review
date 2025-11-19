# ==============================================================================
# Title:        Build Prompts
# Description:  Validate input (PDF) and combine with system and user prompts
# Output:       Character string with entire prompt to be sent to AI model
# ==============================================================================

# Helper Functions -------------------------------------------------------------

#' Validate that a PDF file exists and is readable
#'
#' Checks file existence, readability, and extension.
#' @param file_path Path to PDF file
#' @return Logical TRUE if valid, stops with error if not
validate_pdf_file <- function(file_path) {
  # Check file exists
  if (!file.exists(file_path)) {
    stop(paste0("❌ File not found: ", file_path))
  }

  # Check file is readable
  if (file.access(file_path, mode = 4) != 0) {
    stop(paste0("❌ File is not readable: ", file_path))
  }

  # Check file extension
  if (!grepl("\\.pdf$", tolower(file_path))) {
    warning(paste0("⚠️  File does not have .pdf extension: ", file_path))
  }

  return(TRUE)
}


#' Build extraction prompt from field specifications
#'
#' Creates the full prompt for OpenAI API based on requested metadata fields.
#' @param fields Character vector of field names to extract
#' @return Character string with complete extraction prompt
build_extraction_prompt <- function(fields = DEFAULT_FIELDS) {
  # Validate that requested fields are available
  invalid_fields <- setdiff(fields, names(METADATA_FIELDS))
  if (length(invalid_fields) > 0) {
    stop(paste0("❌ Invalid metadata fields requested: ", paste(invalid_fields, collapse = ", ")))
  }

  # Build field descriptions section
  field_descriptions <- fields |>
    map_chr(~ paste0("- ", .x, ": ", METADATA_FIELDS[[.x]])) |>
    paste(collapse = "\n")

  # Build field names list
  field_names <- paste(fields, collapse = ", ")

  # Substitute into template
  prompt <- EXTRACTION_PROMPT_TEMPLATE |>
    str_replace("\\{field_descriptions\\}", field_descriptions) |>
    str_replace("\\{field_names\\}", field_names)

  return(prompt)
}


#' Parse and validate JSON response from OpenAI API
#'
#' Extracts metadata from API response, validates expected fields are present,
#' and returns as a single-row data frame.
#' @param response API response object from ellmer
#' @param expected_fields Character vector of fields that should be in response
#' @return Data frame with one row containing extracted metadata
parse_extraction_response <- function(response, expected_fields = DEFAULT_FIELDS) {
  # Extract content from response
  # The response structure depends on ellmer's implementation
  # This assumes the response has a content field with the JSON
  content <- tryCatch({
    # Try to get the text content from the response
    if (is.character(response)) {
      response
    } else if ("content" %in% names(response)) {
      response$content
    } else if ("choices" %in% names(response)) {
      response$choices[[1]]$message$content
    } else {
      as.character(response)
    }
  }, error = function(e) {
    stop(paste0("❌ Could not extract content from API response: ", e$message))
  })

  # Parse JSON from content
  parsed_data <- tryCatch({
    fromJSON(content, simplifyVector = FALSE)
  }, error = function(e) {
    stop(paste0("❌ Failed to parse JSON response: ", e$message, "\n\nResponse content: ", content))
  })

  # Validate that all expected fields are present
  missing_fields <- setdiff(expected_fields, names(parsed_data))
  if (length(missing_fields) > 0) {
    warning(paste0("⚠️  Missing fields in API response: ", paste(missing_fields, collapse = ", ")))
    # Add missing fields as NULL
    for (field in missing_fields) {
      parsed_data[[field]] <- NA_character_
    }
  }

  # Convert to data frame row
  # Handle NULL values by converting to NA
  # Handle list values by collapsing into semicolon-separated strings
  df_row <- parsed_data[expected_fields] |>
    map(~ {
      if (is.null(.x)) {
        NA_character_
      } else if (is.list(.x)) {
        # Collapse lists into a single semicolon-separated string
        paste(unlist(.x), collapse = "; ")
      } else {
        as.character(.x)
      }
    }) |>
    as_tibble()

  return(df_row)
}

# Main Functions ---------------------------------------------------------------

#' Extract metadata from a single PDF file
#'
#' Main extraction function that orchestrates the entire process: validates file,
#' loads API key, uploads PDF to OpenAI, sends extraction request, and returns
#' parsed metadata.
#' @param pdf_path Path to PDF file to process. If NULL, opens file chooser dialog.
#' @param fields Character vector of metadata fields to extract (defaults to DEFAULT_FIELDS)
#' @return Data frame with one row containing extracted metadata
#' @export
extract_pdf_metadata <- function(pdf_path = NULL, fields = DEFAULT_FIELDS) {
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

  message(paste0("📄 Processing: ", filename))

  # Make API request using ellmer
  response <- tryCatch({
    # Create chat with GPT-5.1 using ellmer
    chat <- chat_openai(
      model = OPENAI_MODEL,
      api_key = api_key,
      system_prompt = SYSTEM_PROMPT
    )

    # Upload PDF and send request
    # Use content_pdf_file() to encode the PDF for chat input
    result <- chat$chat(
      content_pdf_file(pdf_path),
      prompt
    )

    result
  }, error = function(e) {
    stop(paste0("❌ API request failed for ", filename, ": ", e$message))
  })

  # Parse response
  metadata <- parse_extraction_response(response, expected_fields = fields)

  # Add filename to results
  metadata <- metadata |>
    mutate(filename = filename, .before = 1)

  message(paste0("✅ Completed: ", filename, "\n"))

  return(metadata)
}
