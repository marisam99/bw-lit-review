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
