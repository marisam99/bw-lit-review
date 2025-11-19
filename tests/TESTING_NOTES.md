# Phase 2 Testing Notes

## Overview

This document describes the testing performed for Phase 2: Core Extraction Functions.

## Test Environment Requirements

-   R environment with required packages (tidyverse, ellmer, jsonlite, writexl, dotenv)
-   `.env` file with valid `OPENAI_API_KEY`
-   Sample PDF files for testing

## Testing Approach

### 1. Unit Testing (Component-level)

#### API Key Loading (`load_api_key()`)

**Test Cases:** - ✅ Missing .env file → Should provide clear error message - ✅ Empty API key → Should provide clear error message - ✅ Invalid key format → Should warn about unusual format - ✅ Valid API key → Should return key string

**Expected Behavior:** - Function stops with clear, actionable error messages when .env is missing or API key is not set - Function warns if API key doesn't match expected OpenAI format (starts with "sk-")

#### File Validation (`validate_pdf_file()`)

**Test Cases:** - ✅ Non-existent file → Should stop with error - ✅ File exists but not readable → Should stop with error - ✅ Non-PDF file extension → Should warn user - ✅ File larger than 20MB → Should warn about size - ✅ Valid PDF file → Should return TRUE

**Expected Behavior:** - Clear error messages for file access issues - Warnings for potential issues (large files, non-PDF extensions)

#### Prompt Building (`build_extraction_prompt()`)

**Test Cases:** - ✅ Default fields → Should build complete prompt with all default metadata fields - ✅ Custom field subset → Should build prompt with only requested fields - ✅ Invalid field name → Should stop with error listing invalid fields - ✅ Empty fields vector → Should handle gracefully

**Expected Behavior:** - Prompt includes field descriptions from METADATA_FIELDS configuration - Prompt includes JSON format instructions - Invalid fields are caught before API call

#### Response Parsing (`parse_extraction_response()`)

**Test Cases:** - ✅ Valid JSON with all fields → Should return data frame with expected columns - ✅ Valid JSON with missing fields → Should warn and fill with NA - ✅ Malformed JSON → Should stop with clear error message - ✅ NULL values in response → Should convert to NA_character\_

**Expected Behavior:** - Robust JSON parsing with clear error messages - Missing fields handled gracefully - Returns tibble (tidyverse data frame) with one row

### 2. Integration Testing (Full Workflow)

#### Single PDF Extraction (`extract_pdf_metadata()`)

**Test Files:** - `Using GPT-5.1 - OpenAI API.pdf` (included in repository)

**Test Cases:** - 📋 Valid PDF with default fields → Should extract all metadata and return data frame - 📋 Valid PDF with custom fields → Should extract only requested fields - 📋 Large PDF (\>20MB) → Should warn but continue processing - 📋 Scanned PDF vs text PDF → Should handle both (GPT-5.1 has OCR capabilities) - 📋 PDF with complex layout (tables, figures) → Should extract metadata successfully

**Expected Behavior:** - Progress messages show current file being processed - Success/error messages use color-coded emojis - API errors are caught and reported clearly - Timeout handling works for slow responses - Returned data frame includes filename column

### 3. Edge Cases and Error Scenarios

**Scenarios to Test:** - 📋 API timeout (\>120 seconds) → Should fail gracefully with timeout message - 📋 API rate limit error → Should report error (retry logic in Phase 3) - 📋 Invalid API key → Should fail with authentication error - 📋 Network connectivity issues → Should fail with clear error - 📋 Malformed PDF file → Should report extraction failure - 📋 PDF with no extractable text → Should return with NA values where appropriate

## Testing Script

A test script is provided at `tests/test_extract_metadata.R` that: 1. Tests file validation with valid and invalid files 2. Tests prompt building with various field configurations 3. Tests response parsing with mock JSON data 4. Tests API key loading (requires .env file) 5. Tests full extraction workflow (requires .env file and API access)

## Notes and Observations