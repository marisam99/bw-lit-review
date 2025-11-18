# ==============================================================================
# Title:        Extract Metadata
# Description:  Main extraction functions for processing PDF files through the
#               OpenAI API to extract bibliographic metadata and key findings.
# Output:       Data frame with one row per PDF containing extracted metadata
# ==============================================================================

# Configs ----------------------------------------------------------------------

source("config/dependencies.R")
source("config/settings.R")

# Helper Functions -------------------------------------------------------------

#' Load and validate OpenAI API key from environment
#'
#' Loads .env file and validates that OPENAI_API_KEY is present and non-empty.
#' @return Character string with API key, or stops with error if not found
load_api_key <- function() {
  # Load .env file if it exists
  if (file.exists(".env")) {
    load_dot_env(".env")
  } else {
    stop("❌ .env file not found. Please create one based on .env.example and add your OPENAI_API_KEY")
  }

  # Get API key from environment
  api_key <- Sys.getenv("OPENAI_API_KEY")

  # Validate API key exists and is not empty
  if (api_key == "" || is.null(api_key)) {
    stop("❌ OPENAI_API_KEY not found in .env file. Please add your OpenAI API key")
  }

  # Basic format validation (OpenAI keys typically start with "sk-")
  if (!grepl("^sk-", api_key)) {
    warning("⚠️  API key format looks unusual. OpenAI keys typically start with 'sk-'")
  }

  return(api_key)
}


#' Validate that a PDF file exists and is readable
#'
#' Checks file existence, readability, and size, with warnings for large files.
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

  # Check file size and warn if large
  file_size_mb <- file.size(file_path) / (1024^2)
  if (file_size_mb > FILE_SIZE_WARNING_MB) {
    warning(paste0("⚠️  Large file (", round(file_size_mb, 1), " MB). Processing may take longer and cost more."))
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
  df_row <- parsed_data[expected_fields] |>
    map(~ if (is.null(.x)) NA_character_ else as.character(.x)) |>
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
    # According to settings, GPT-5.1 uses Responses API with specific parameters
    chat <- chat_openai(
      model = OPENAI_MODEL,
      api_key = api_key,
      system_prompt = SYSTEM_PROMPT
    )

    # Upload PDF and send request
    # ellmer supports file uploads via the turns() function with type = "file"
    result <- chat$chat(
      turns = list(
        turn(
          role = "user",
          content = list(
            content_file(pdf_path, type = "pdf"),
            prompt
          )
        )
      ),
      max_tokens = API_MAX_TOKENS,
      reasoning_effort = REASONING_EFFORT,
      verbosity = VERBOSITY_LEVEL,
      timeout = API_TIMEOUT_SECONDS
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
