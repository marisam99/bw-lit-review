# ==============================================================================
# Title:        Process Response
# Description:  Parses and reformats JSON response from API
# Output:       1-row dataframe with metadata in requested fields' columns
# ==============================================================================

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