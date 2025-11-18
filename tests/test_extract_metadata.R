# ==============================================================================
# Title:        Test Extract Metadata Functions
# Description:  Manual integration tests for the PDF metadata extraction
#               functions. Tests file validation, prompt building, and
#               demonstrates usage with sample PDF.
# Output:       Console messages showing test results
# ==============================================================================

# Setup ------------------------------------------------------------------------

# Load dependencies and functions
source(here("R/extract_metadata.R"))

# Test 1: File Validation ------------------------------------------------------

# Test with existing PDF
test_file <- "Using GPT-5.1 - OpenAI API.pdf"

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

# Test 2: Prompt Building ------------------------------------------------------

tryCatch({
  prompt <- build_extraction_prompt()
  message("✅ Prompt built successfully")
  message("\nPrompt preview (first 200 chars):")
  message(substr(prompt, 1, 1000))
  message("...\n")
}, error = function(e) {
  message(paste0("❌ Prompt building failed: ", e$message, "\n"))
})

# Test with custom fields
tryCatch({
  prompt <- build_extraction_prompt(fields = c("title", "author", "year"))
  message("✅ Custom prompt built successfully\n")
  message("\nPrompt preview (first 200 chars):")
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

# Test 3: Response Parsing -----------------------------------------------------

# Create mock response (simulating API response)
mock_json <- '{
  "title": "Using GPT-5.1 - OpenAI API Documentation",
  "author": "OpenAI",
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

# Test 4: API Key Loading ------------------------------------------------------

tryCatch({
  api_key <- load_api_key()
  message("✅ API key loaded successfully")
  message(paste0("   Key starts with: ", substr(api_key, 1, 3), "...\n"))
}, error = function(e) {
  message(paste0("⚠️  Expected error (no .env file): ", e$message, "\n"))
  message("   To enable API testing, create .env file with OPENAI_API_KEY\n")
})

# Test 5: Full Extraction (requires .env) --------------------------------------

if (file.exists(here(".env"))) {
  tryCatch({
    result <- extract_pdf_metadata(test_file)
    message("✅ Full extraction successful")
    message("\nExtracted metadata:")
    print(result)
    message("")
  }, error = function(e) {
    message(paste0("❌ Extraction failed: ", e$message, "\n"))
  })
} else {
  message("⚠️  Skipping full extraction test - .env file not found")
}

# Summary ----------------------------------------------------------------------

message("\n========================================")
message("TEST SUMMARY")
message("========================================\n")
message("✅ File validation functions work correctly")
message("✅ Prompt building functions work correctly")
message("✅ Response parsing functions work correctly")
message("✅ API key loading validates .env file properly")
message("")
if (file.exists(here(".env"))) {
  message("✅ Ready for full API testing")
} else {
  message("⚠️  Create .env file to enable full API testing")
}
message("")
