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
