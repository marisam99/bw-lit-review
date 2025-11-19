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
**Completion Date:** November 19, 2025
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
- `/R/api_call_extraction.R` - Enhanced with built-in retry logic:
  - `extract_pdf_metadata()` - Now includes automatic retry with exponential backoff
  - `create_error_log_entry()` - Structured error logging helper
- `/R/batch_processing.R` - Batch orchestration functions:
  - `process_pdf_batch()` - Main function with interactive file picker, progress tracking, and batch coordination
  - `display_progress()` - Real-time progress indicators
  - `generate_error_summary()` - Human-readable error reports
  - `save_error_log()` - Error log export to CSV
- Error log format specification (CSV with timestamp, filename, error_type, error_message, attempt_number)
- Interactive file picker supporting single or multiple file selection

### Implementation Notes:
- Retry mechanism built into `extract_pdf_metadata()` - always active
- Uses exponential backoff (2^attempt * base_delay) for transient failures
- Detects retryable errors (timeouts, rate limits, network issues) vs permanent failures
- Max retry attempts configurable via MAX_RETRY_ATTEMPTS setting (default 3)
- Progress tracking shows percentage complete, success/fail counts, and current file
- Comprehensive final summary includes timing statistics and average time per file
- Error logging captures all attempts, not just final failures
- Batch processing continues even if individual files fail (partial results)
- Rate limiting configurable via settings (default 0.5s between requests)
- All console output uses color-coded emojis for visual clarity (📊 progress, ✅ success, ❌ error, ⚠️ warning)
- Returns structured list with results data frame, error log, and summary statistics
- Always opens file picker - user can select 1 or more files
- Uses tcltk::tk_choose.files() for multi-file selection with fallback to repeated file.choose()
- Simple single-function interface: `process_pdf_batch()` handles everything
- Single extraction function works for both individual and batch use cases
- Added "organization" field to DEFAULT_FIELDS for capturing publishing organization
- Updated `run_summarize_literature.R` to use batch processing with automatic error logging and results summary

---

## Phase 4: User Interface and Main Function ✅ COMPLETE (Simplified)

**Status:** Completed (Simplified Implementation)
**Completion Date:** November 19, 2025
**Dependencies:** Phase 3 complete

### Objectives:
Create simple, user-friendly main function and supporting utilities for file selection and output management.

**Note:** This phase was completed in a simplified form. Instead of creating separate utility functions and a complex main function, we integrated batch processing directly into `run_summarize_literature.R`, which provides a streamlined user experience with the same core functionality.

### Tasks:

#### 4.1: File Selection Utilities ✅ COMPLETE (Integrated)
- [x] Interactive file picker implemented in `process_pdf_batch()` (Phase 3)
- [x] Supports single and multiple file selection via tcltk
- [x] PDF validation built into `extract_pdf_metadata()`
- [ ] ~~Directory scanning~~ (Not implemented - users select files manually via picker)

#### 4.2: Output Management ⚠️ SIMPLIFIED
- [x] Results returned as data frame for user manipulation
- [x] Optional CSV save functionality provided (commented code in `run_summarize_literature.R`)
- [x] Automatic error log saving to `tests/error_logs/` with timestamps
- [ ] ~~Separate `save_results()` utility function~~ (Not needed - users can use standard `write_csv()`)
- [ ] ~~Excel output~~ (Not implemented - CSV is sufficient)

#### 4.3: Main Function ✅ COMPLETE (Via Script)
- [x] `run_summarize_literature.R` serves as main entry point
- [x] Calls `process_pdf_batch()` with interactive file selection
- [x] Uses DEFAULT_FIELDS from settings.R
- [x] Displays results summary
- [x] Saves error logs automatically when failures occur
- [ ] ~~Complex parameter-driven main function~~ (Not needed - simpler script approach works well)

#### 4.4: Integration Testing ✅ COMPLETE
- [x] Tested via `tests/test_batch_processing.R`
- [x] Workflow validated: file selection → processing → results
- [x] Custom fields supported via function parameters
- [x] CSV output tested

### Completed Deliverables:
- `/run_summarize_literature.R` - Main user-facing script with batch processing, error handling, and results summary
- `process_pdf_batch()` in `/R/batch_processing.R` - Handles file selection, processing, and output coordination
- `save_error_log()` in `/R/batch_processing.R` - Error log export utility
- Commented CSV export code in `run_summarize_literature.R` for users to enable if desired

### Implementation Notes:
- Simplified approach: direct script execution instead of complex function API
- File selection handled by interactive picker (no need for path/directory parameters)
- Error logging automatic and user-friendly
- Results returned as data frame for flexible downstream use
- Users can easily customize by editing `run_summarize_literature.R` or calling functions directly
- Maintains simplicity while achieving all core objectives

---

## Phase 5: Documentation

**Status:** Not Started
**Estimated Duration:** 1-2 development sessions
**Dependencies:** Phase 4 complete

### Objectives:
Create comprehensive documentation to enable users to understand, configure, and use the tool effectively.

### Tasks:

#### 5.1: README Documentation
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

#### 5.2: Code Documentation
- [ ] Review all function comments for clarity and completeness
- [ ] Ensure all scripts have proper headers
- [ ] Verify inline comments explain "why" not "what"
- [ ] Add examples in comments where helpful
- [ ] Review all code for adherence to coding standards specified in Claude.md

#### 5.3: Configuration Documentation
- [ ] Create `/config/README.md` explaining:
  - Available OpenAI models and tradeoffs
  - How to modify metadata fields
  - Rate limiting and batch processing settings
  - Environment variable requirements
- [ ] Document recommended settings for different use cases

### Deliverables:
- Complete `/README.md` file
- `/config/README.md` configuration guide
- Updated code comments and documentation
- Known limitations documented in README

---

## Phase 6: Shiny App Development

**Status:** Not Started
**Estimated Duration:** 2-3 development sessions
**Dependencies:** Phase 5 complete

### Objectives:
Create a user-friendly Shiny web application that provides a graphical interface for non-technical users to process PDFs without using R scripts directly.

### Tasks:

#### 6.1: UI Design and Layout
- [ ] Create main page layout with file upload widget
- [ ] Add metadata field selection checkboxes (pre-populated with DEFAULT_FIELDS)
- [ ] Design results display area with data table
- [ ] Add download button for CSV export
- [ ] Create progress indicators and status messages
- [ ] Design error log viewer panel

#### 6.2: Core Shiny Functionality
- [ ] Implement file upload handler supporting multiple PDFs
- [ ] Connect UI to `process_pdf_batch()` backend function
- [ ] Add reactive processing triggered by "Process PDFs" button
- [ ] Implement progress tracking using Shiny progress bars
- [ ] Display results in interactive data table (using DT package)
- [ ] Enable CSV download of results

#### 6.3: Configuration and Settings
- [ ] Add settings panel for batch processing parameters (delay, retry attempts)
- [ ] Include API model selection dropdown (if multiple models available)
- [ ] Add option to customize system prompt
- [ ] Include help/instructions panel with usage guide

#### 6.4: Error Handling and User Feedback
- [ ] Display error messages in user-friendly format
- [ ] Show error log summary with expandable details
- [ ] Add validation for file types and sizes
- [ ] Implement session state management
- [ ] Add "Clear All" functionality to reset application

#### 6.5: Testing and Polish
- [ ] Test with various file upload scenarios
- [ ] Verify all UI elements work correctly
- [ ] Test error handling paths
- [ ] Optimize UI responsiveness
- [ ] Add loading spinners and visual feedback

### Deliverables:
- `/app.R` - Main Shiny application file
- `/R/shiny_helpers.R` - Helper functions for Shiny app (optional)
- Updated dependencies.R with shiny and DT packages
- Shiny app usage documentation in README
- Screenshots of the application interface (optional)

### Implementation Notes:
- Use existing backend functions (`process_pdf_batch()`, `extract_pdf_metadata()`)
- Keep UI simple and intuitive for non-technical users
- Ensure API key is loaded from .env file (not exposed in UI)
- Handle long-running API calls gracefully with progress feedback
- Allow users to continue working after download (don't reset unnecessarily)

---

## Phase 7: Testing, Refinement and Deployment

**Status:** Not Started
**Estimated Duration:** 2-3 development sessions
**Dependencies:** Phase 6 complete

### Objectives:
Test the tool (both R scripts and Shiny app) with real documents, polish based on testing feedback, optimize performance, and prepare for production use.

### Tasks:

#### 7.1: Manual Integration Testing
- [ ] Test complete workflow with real research PDFs (both R scripts and Shiny app)
- [ ] Verify metadata extraction accuracy across different document types
- [ ] Test edge cases:
  - PDFs without clear metadata
  - Large files (> 20MB)
  - Scanned documents vs. text PDFs
  - Multi-author papers
  - Documents with tables and figures
- [ ] Document any limitations or failure patterns
- [ ] Record test results and any issues discovered
- [ ] Test Shiny app with multiple concurrent users (if applicable)

#### 7.2: Performance Optimization
- [ ] Review API timeout and retry settings based on test results
- [ ] Optimize batch processing delay if needed
- [ ] Test with larger batches (20+ files)
- [ ] Monitor and document API costs per file
- [ ] Optimize Shiny app performance and memory usage

#### 7.3: User Experience Refinement
- [ ] Improve error messages based on testing feedback
- [ ] Enhance progress reporting clarity (both CLI and Shiny)
- [ ] Verify all user-facing messages are actionable
- [ ] Polish console output formatting
- [ ] Refine Shiny app UI/UX based on user testing

#### 7.4: Final Code Review
- [ ] Verify dependency management is clean
- [ ] Remove any debug code or comments
- [ ] Ensure consistent code organization across all scripts
- [ ] Final verification of coding standards compliance
- [ ] Code review for Shiny app security (API key handling, input validation)

#### 7.5: Deployment Preparation
- [ ] Create example .env file with clear instructions
- [ ] Prepare sample PDFs for testing (if applicable)
- [ ] Write deployment checklist (for both R scripts and Shiny app)
- [ ] Document how to deploy Shiny app (local vs. server)
- [ ] Tag stable version in git

### Deliverables:
- Test results documentation with edge case analysis
- Production-ready codebase
- Deployment checklist
- Performance benchmarks and API cost estimates
- Final git tag (v1.0.0)

---

## Success Criteria

The project will be considered complete when:

1. ✅ Tool can process multiple PDF files in batch
2. ✅ Metadata extraction works reliably with GPT-5.1 API
3. ✅ Output saves to CSV format (results returned as data frame with optional CSV export)
4. ✅ Error handling manages failures gracefully with retry logic and error logging
5. ⏳ Documentation enables non-technical users to run the tool (Phase 5 - In Progress)
6. ⏳ Shiny app provides user-friendly GUI interface (Phase 6 - Not Started)
7. ✅ Code follows all standards specified in Claude.md
8. ⏳ Testing validates accuracy with real research documents (Phase 7 - Pending manual testing)

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
- **Phase 3:** ✅ Complete (Nov 18-19, 2025)
- **Phase 4:** ✅ Complete - Simplified (Nov 19, 2025)
- **Phase 5:** ⏳ In Progress (1-2 sessions, ~3-5 days) - Documentation
- **Phase 6:** Not Started (2-3 sessions, ~1 week) - Shiny App Development
- **Phase 7:** Not Started (2-3 sessions, ~1 week) - Testing, Refinement, and Deployment

**Total Estimated Time:** 5-6 weeks of active development
**Actual Progress:** Phases 1-4 completed in ~3 days (ahead of schedule due to simplified Phase 4 approach)

---

## Change Log

| Date | Phase | Change Description |
|------|-------|-------------------|
| 2025-11-17 | Phase 1 | Initial infrastructure setup completed |
| 2025-11-17 | Planning | Project workplan created |
| 2025-11-17 | Phase 2 | Core extraction functions implemented with API auth, file validation, prompt building, and response parsing |
| 2025-11-18 | Phase 3 | Batch processing with retry logic, error handling, progress tracking, and error logging implemented |
| 2025-11-19 | Phase 3 | Added "organization" field to DEFAULT_FIELDS in settings.R for capturing publishing organization metadata |
| 2025-11-19 | Phase 4 | Updated `run_summarize_literature.R` to use batch processing with automatic error logging and results summary display |
| 2025-11-19 | Phase 4 | Completed Phase 4 in simplified form - integrated batch processing directly into main script rather than creating separate utility functions |
| 2025-11-19 | Planning | Restructured Phases 5 and 6: Phase 5 now focuses on documentation only; manual integration testing moved to Phase 6; added coding standards review task |
| 2025-11-19 | Planning | Added new Phase 6 for Shiny App Development; renumbered previous Phase 6 to Phase 7; updated success criteria to include Shiny app requirement |

