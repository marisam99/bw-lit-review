# ==============================================================================
# Title:        Test Extract Metadata Functions
# Description:  Manual integration tests for the PDF metadata extraction
#               functions. Tests file validation, prompt building, and
#               demonstrates usage with sample PDF.
# Output:       Console messages showing test results
# ==============================================================================

# Setup ------------------------------------------------------------------------

# Load dependencies and constants
source(here("config/dependencies"))
source(here("config/settings.R"))

# Test 1: API Key Loading ------------------------------------------------------

tryCatch({
  api_key <- load_api_key()
  message("✅ API key loaded successfully")
  message(paste0("   Key starts with: ", substr(api_key, 1, 3), "...\n"))
}, error = function(e) {
  message(paste0("⚠️  Expected error (no .env file): ", e$message, "\n"))
  message("   To enable API testing, create .env file with OPENAI_API_KEY\n")
})

# Test 2: File Validation ------------------------------------------------------

source(here("R/build_prompt.R"))

# Test with existing PDF
test_file <- here("tests","test_samples","Abott_2020.pdf")

tryCatch({
  result <- validate_pdf_file(test_file)
  message("✅ File validation passed\n")
}, error = function(e) {
  message(paste0("❌ File validation failed: ", e$message, "\n"))
})

# Test with non-existent file
tryCatch({
  result <- validate_pdf_file("nonexistent_file.pdf")
  message("❌ Should have failed but didn't\n")
}, error = function(e) {
  message(paste0("✅ Correctly caught error: ", e$message, "\n"))
})

# Test 3: Prompt Building ------------------------------------------------------

tryCatch({
  prompt <- build_extraction_prompt()
  message("✅ Prompt built successfully")
  message("\nPrompt preview (first 1000 chars):")
  message(substr(prompt, 1, 1000))
  message("...\n")
}, error = function(e) {
  message(paste0("❌ Prompt building failed: ", e$message, "\n"))
})

# Test with custom fields
tryCatch({
  prompt <- build_extraction_prompt(fields = c("title", "authors", "year"))
  message("✅ Custom prompt built successfully\n")
  message("\nPrompt preview (first 1000 chars):")
  message(substr(prompt, 1, 1000))
  message("...\n")
}, error = function(e) {
  message(paste0("❌ Custom prompt building failed: ", e$message, "\n"))
})

# Test with invalid field
tryCatch({
  prompt <- build_extraction_prompt(fields = c("title", "invalid_field"))
  message("❌ Should have failed but didn't\n")
}, error = function(e) {
  message(paste0("✅ Correctly caught error: ", e$message, "\n"))
})

# Test 4: Response Parsing -----------------------------------------------------

source(here("R/process_response.R"))

# Create mock response (simulating API response)
mock_json <- '{
  "title": "Using GPT-5.1 - OpenAI API Documentation",
  "authors": "John Doe",
  "organization": "OpenAI",
  "year": "2024",
  "state": null,
  "key_findings": "GPT-5.1 introduces enhanced reasoning capabilities and improved API features for developers."
}'

tryCatch({
  result <- parse_extraction_response(mock_json)
  message("✅ Response parsing successful")
  message("\nParsed data:")
  print(result)
  message("")
}, error = function(e) {
  message(paste0("❌ Response parsing failed: ", e$message, "\n"))
})

# Test with malformed JSON
tryCatch({
  result <- parse_extraction_response("{ invalid json }")
  message("❌ Should have failed but didn't\n")
}, error = function(e) {
  message(paste0("✅ Correctly caught error: ", e$message, "\n"))
})
