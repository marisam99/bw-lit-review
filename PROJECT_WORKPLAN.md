# Project Workplan: PDF Metadata Extraction Tool

## Project Overview

**Goal:** Build an R-based tool that processes multiple PDF files through the OpenAI API to extract metadata (title, author, year, state, key findings) and outputs results to CSV/Excel format.

**Target Users:** Project Managers and Support staff conducting desk research who need quick understanding of existing research literature.

**Current Status:** Phase 3 (Batch Processing and Error Handling) complete

---

## Phase 1: Infrastructure Setup ✅ COMPLETE

**Status:** Completed
**Completion Date:** November 17, 2025

### Completed Tasks:
- [x] Create directory structure (config, R, tests)
- [x] Set up dependencies.R with required packages (tidyverse, ellmer, jsonlite, writexl, dotenv)
- [x] Configure settings.R with OpenAI API parameters for GPT-5.1 model
- [x] Define metadata field specifications
- [x] Set up prompt templates and output configuration
- [x] Create .env.example file for API key management
- [x] Initialize git repository with appropriate .gitignore

### Deliverables:
- `/config/dependencies.R` - Package management
- `/config/settings.R` - API and tool configuration
- `/R/template_new script.R` - Script structure template
- `.env.example` - Environment variable template
- `.gitignore` - Version control exclusions

---

## Phase 2: Core Extraction Functions ✅ COMPLETE

**Status:** Completed
**Completion Date:** November 17, 2025
**Dependencies:** Phase 1 complete

### Objectives:
Build the core functions that handle single PDF extraction, API communication, and JSON response parsing.

### Tasks:

#### 2.1: API Connection and Authentication
- [x] Create function to load and validate API key from .env file
- [x] Implement error handling for missing/invalid API credentials
- [x] Test basic connection to OpenAI API using ellmer package

#### 2.2: Single PDF Extraction Function
- [x] Build `extract_pdf_metadata()` function that:
  - Accepts a single PDF file path
  - Validates file exists and is readable
  - Constructs extraction prompt based on requested metadata fields
  - Uploads PDF directly to OpenAI API using ellmer's file upload capability
  - Sends request using GPT-5.1 with configured parameters
  - Returns API response
- [x] Add file size validation with warning for files > 20MB
- [x] Implement timeout handling (120 seconds default)

#### 2.3: Response Parsing and Validation
- [x] Create `parse_extraction_response()` function that:
  - Parses JSON response from API
  - Validates all requested fields are present
  - Handles null/missing values appropriately
  - Returns structured data frame row
- [x] Add error handling for malformed JSON responses
- [x] Implement fallback logic for partial extraction failures

#### 2.4: Single-File Testing
- [x] Test with sample PDF in repository
- [x] Verify all metadata fields extract correctly
- [x] Validate JSON parsing and data frame output
- [x] Document any edge cases or limitations discovered

### Completed Deliverables:
- `/R/extract_metadata.R` - Core extraction functions with:
  - `load_api_key()` - API authentication with validation
  - `validate_pdf_file()` - File validation with size warnings
  - `build_extraction_prompt()` - Dynamic prompt construction
  - `parse_extraction_response()` - JSON parsing with error handling
  - `extract_pdf_metadata()` - Main extraction orchestration function
- `/tests/test_extract_metadata.R` - Comprehensive test script
- `/tests/TESTING_NOTES.md` - Detailed testing documentation and expected behaviors

### Implementation Notes:
- All functions follow tidyverse style guide with |> pipes
- Error messages use color-coded emojis (❌ errors, ⚠️ warnings, ✅ success)
- Robust parameter validation prevents API calls with invalid inputs
- File size warning threshold set at 20MB
- Timeout set to 120 seconds for large PDF processing
- Response parsing handles NULL values and missing fields gracefully
- Functions designed for easy integration into batch processing (Phase 3)

---

## Phase 3: Batch Processing and Error Handling ✅ COMPLETE

**Status:** Completed
**Completion Date:** November 18, 2025
**Dependencies:** Phase 2 complete

### Objectives:
Enable multi-file processing with robust error handling, retry logic, and progress tracking.

### Tasks:

#### 3.1: Batch Processing Function
- [x] Create `process_pdf_batch()` function that:
  - Accepts vector of PDF file paths
  - Accepts optional metadata fields parameter (defaults to DEFAULT_FIELDS)
  - Processes files sequentially with configurable delay
  - Combines individual results into single data frame
  - Returns final results with filename column added
- [x] Implement rate limiting (0.5 second delay between requests)
- [x] Add progress indicators with colored emojis for user feedback

#### 3.2: Error Handling and Retry Logic
- [x] Implement retry mechanism (up to 3 attempts) for:
  - Network timeouts
  - API rate limit errors
  - Temporary server errors
- [x] Create error logging that captures:
  - Failed filename
  - Error type and message
  - Timestamp
  - Retry attempt number
- [x] Build partial results handling (continue processing even if some files fail)

#### 3.3: Progress and Status Reporting
- [x] Add console messages showing:
  - Total files to process
  - Current file being processed (with count)
  - Success/failure status for each file
  - Final summary (successful, failed, total time)
- [x] Use color-coded emojis and `\n` for readability
- [x] Make messages user-friendly and actionable

#### 3.4: Multi-File Testing
- [x] Test with batch of 3-5 PDFs
- [x] Verify error handling with intentionally problematic file
- [x] Test retry logic by temporarily breaking API connection
- [x] Validate progress messages display correctly

### Completed Deliverables:
- `/R/batch_processing.R` - Batch processing and error handling functions with:
  - `process_pdf_batch()` - Main batch orchestration with progress tracking and multi-file picker
  - `extract_batch_interactive()` - Convenience wrapper for quick interactive use
  - `extract_with_retry()` - Retry logic with exponential backoff
  - `create_error_log_entry()` - Structured error logging
  - `display_progress()` - Real-time progress indicators
  - `generate_error_summary()` - Human-readable error reports
  - `save_error_log()` - Error log export to CSV
- Error log format specification (CSV with timestamp, filename, error_type, error_message, attempt_number)
- Multi-file picker using tcltk with fallback to repeated file.choose()

### Implementation Notes:
- Retry mechanism uses exponential backoff (2^attempt * base_delay)
- Detects retryable errors (timeouts, rate limits, network issues) vs permanent failures
- Progress tracking shows percentage complete, success/fail counts, and current file
- Comprehensive final summary includes timing statistics and average time per file
- Error logging captures all attempts, not just final failures
- Batch processing continues even if individual files fail (partial results)
- Rate limiting configurable via settings (default 0.5s between requests)
- All console output uses color-coded emojis for visual clarity (📊 progress, ✅ success, ❌ error, ⚠️ warning)
- Returns structured list with results data frame, error log, and summary statistics
- Interactive multi-file picker using tcltk::tk_choose.files() for selecting multiple PDFs at once
- Fallback to repeated file.choose() if tcltk not available
- Can call `process_pdf_batch()` with no arguments to open file picker automatically
- `extract_batch_interactive()` provides simplified interface returning just the results

---

## Phase 4: User Interface and Main Function

**Status:** Not Started
**Estimated Duration:** 1-2 development sessions
**Dependencies:** Phase 3 complete

### Objectives:
Create simple, user-friendly main function and supporting utilities for file selection and output management.

### Tasks:

#### 4.1: File Selection Utilities
- [ ] Create `select_pdf_files()` helper that:
  - Accepts directory path or vector of file paths
  - Validates files are PDFs
  - Returns cleaned list of valid file paths
  - Warns about skipped non-PDF files
- [ ] Add option to use interactive file picker (if running in RStudio)
- [ ] Handle both individual files and directory scanning

#### 4.2: Output Management
- [ ] Create `save_results()` function that:
  - Accepts results data frame
  - Accepts output directory path
  - Accepts format preference (csv or excel)
  - Generates timestamped filename
  - Saves file and returns full path
- [ ] Add validation for output directory existence
- [ ] Create directory if it doesn't exist
- [ ] Display success message with file location

#### 4.3: Main Function
- [ ] Build `extract_lit_review_metadata()` main function that:
  - Accepts pdf_files (paths or directory)
  - Accepts metadata_fields (optional, uses defaults)
  - Accepts output_dir (optional, uses current working directory)
  - Accepts output_format (optional, defaults to csv)
  - Orchestrates: file selection → batch processing → saving results
  - Returns results data frame invisibly
- [ ] Add comprehensive parameter validation
- [ ] Include informative error messages

#### 4.4: Integration Testing
- [ ] Test complete workflow from file selection through output
- [ ] Verify default parameters work correctly
- [ ] Test custom metadata field selection
- [ ] Validate both CSV and Excel output formats
- [ ] Test with various directory structures

### Deliverables:
- `/R/main_function.R` - Primary user-facing function
- `/R/file_utils.R` - File selection and output utilities
- Example usage script

---

## Phase 5: Testing and Documentation

**Status:** Not Started
**Estimated Duration:** 2-3 development sessions
**Dependencies:** Phase 4 complete

### Objectives:
Create comprehensive documentation and perform end-to-end testing to ensure tool reliability.

### Tasks:

#### 5.1: Manual Integration Testing
- [ ] Test complete workflow with real research PDFs
- [ ] Verify metadata extraction accuracy across different document types
- [ ] Test edge cases:
  - PDFs without clear metadata
  - Large files (> 20MB)
  - Scanned documents vs. text PDFs
  - Multi-author papers
  - Documents with tables and figures
- [ ] Document any limitations or failure patterns

#### 5.2: README Documentation
- [ ] Write **Overview** section:
  - Project description
  - Input/output specifications
  - Key features and limitations
- [ ] Write **Quick Start** section:
  - Package installation instructions
  - API key setup steps
  - Basic function call example
- [ ] Write **Examples** section:
  - Simple single-directory example
  - Custom metadata fields example
- [ ] Write **How It Works** section:
  - Architecture overview (API flow, function organization)
  - Output structure description
  - Design decisions and rationale
- [ ] Write **Configuration** section:
  - API model options
  - Customizing metadata fields
  - Adjusting batch processing settings
- [ ] Add **Support** section with contact information

#### 5.3: Code Documentation
- [ ] Review all function comments for clarity and completeness
- [ ] Ensure all scripts have proper headers
- [ ] Verify inline comments explain "why" not "what"
- [ ] Add examples in comments where helpful

#### 5.4: Configuration Documentation
- [ ] Create `/config/README.md` explaining:
  - Available OpenAI models and tradeoffs
  - How to modify metadata fields
  - Rate limiting and batch processing settings
  - Environment variable requirements
- [ ] Document recommended settings for different use cases

### Deliverables:
- Complete `/README.md` file
- `/config/README.md` configuration guide
- Test results documentation
- Known limitations list

---

## Phase 6: Refinement and Deployment

**Status:** Not Started
**Estimated Duration:** 1-2 development sessions
**Dependencies:** Phase 5 complete

### Objectives:
Polish the tool based on testing feedback, optimize performance, and prepare for production use.

### Tasks:

#### 6.1: Performance Optimization
- [ ] Review API timeout and retry settings
- [ ] Optimize batch processing delay if needed
- [ ] Test with larger batches (20+ files)
- [ ] Monitor and document API costs per file

#### 6.2: User Experience Refinement
- [ ] Improve error messages based on testing feedback
- [ ] Enhance progress reporting clarity
- [ ] Verify all user-facing messages are actionable
- [ ] Polish console output formatting

#### 6.3: Final Code Review
- [ ] Check adherence to coding standards (tidyverse style, naming conventions)
- [ ] Verify dependency management is clean
- [ ] Remove any debug code or comments
- [ ] Ensure consistent code organization across all scripts

#### 6.4: Deployment Preparation
- [ ] Create example .env file with clear instructions
- [ ] Prepare sample PDFs for testing (if applicable)
- [ ] Write deployment checklist
- [ ] Tag stable version in git

### Deliverables:
- Production-ready codebase
- Deployment checklist
- Performance benchmarks
- Final git tag (v1.0.0)

---

## Success Criteria

The project will be considered complete when:

1. ✅ Tool can process multiple PDF files in batch
2. ✅ Metadata extraction works reliably with GPT-5.1 API
3. ✅ Output saves to CSV or Excel format as specified
4. ✅ Error handling manages failures gracefully
5. ✅ Documentation enables non-technical users to run the tool
6. ✅ Code follows all standards specified in Claude.md
7. ✅ Testing validates accuracy with real research documents

---

## Risk Assessment and Mitigation

### Technical Risks:

**Risk:** OpenAI API changes or model availability
**Mitigation:** Use ellmer package which abstracts API details; document model requirements clearly

**Risk:** PDF format variations cause extraction failures
**Mitigation:** Test with diverse PDF types; implement robust error handling; document limitations

**Risk:** API costs exceed budget for large batches
**Mitigation:** Add file size warnings; document estimated costs; implement batch size limits if needed

### Project Risks:

**Risk:** Extracted metadata accuracy is insufficient
**Mitigation:** Test with real documents early; iterate on prompts; consider adding validation step

**Risk:** Tool is too complex for target users
**Mitigation:** Focus on simple main function; provide clear examples; get user feedback

---

## Notes and Assumptions

1. **API Access:** Assumes user has OpenAI API access with GPT-5.1 availability
2. **File Formats:** Tool focuses on PDF files only; other formats out of scope
3. **Testing:** Manual testing is sufficient; automated unit tests not required per testing philosophy
4. **Scalability:** Initial version optimized for batches of 10-50 files, not hundreds
5. **State Field:** U.S.-specific; may need modification for international projects
6. **Vision Capabilities:** GPT-5.1 can read tables/figures in PDFs directly

---

## Timeline Estimate

- **Phase 1:** ✅ Complete (Nov 17, 2025)
- **Phase 2:** ✅ Complete (Nov 17, 2025)
- **Phase 3:** 2-3 sessions (~1 week)
- **Phase 4:** 1-2 sessions (~3-5 days)
- **Phase 5:** 2-3 sessions (~1 week)
- **Phase 6:** 1-2 sessions (~3-5 days)

**Total Estimated Time:** 4-5 weeks of active development

---

## Change Log

| Date | Phase | Change Description |
|------|-------|-------------------|
| 2025-11-17 | Phase 1 | Initial infrastructure setup completed |
| 2025-11-17 | Planning | Project workplan created |
| 2025-11-17 | Phase 2 | Core extraction functions implemented with API auth, file validation, prompt building, and response parsing |
| 2025-11-18 | Phase 3 | Batch processing with retry logic, error handling, progress tracking, and error logging implemented |

