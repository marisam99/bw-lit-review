# ==============================================================================
# Title:        Settings and Configuration
# Description:  Centralized configuration for OpenAI API calls, metadata fields,
#               and default options. Modify these values to customize tool behavior
#               without changing core functions.
# Output:       None (defines constants and configuration variables)
# ==============================================================================

# OpenAI API Configuration -------------------------------------------------

# Model to use for extraction
OPENAI_MODEL <- "gpt-4o-mini"

# API parameters
API_TEMPERATURE <- 0.3  # Lower = more consistent, higher = more creative
API_MAX_TOKENS <- 1500  # Maximum tokens in response
API_TIMEOUT_SECONDS <- 60  # Request timeout

# Metadata Field Definitions -----------------------------------------------

# Available metadata fields that can be extracted
METADATA_FIELDS <- list(
  title = "The full title of the document",
  author = "Primary author(s) or organization",
  year = "Publication year",
  state = "U.S. state(s) mentioned or relevant to the research (if applicable)",
  key_findings = "A 2-3 sentence summary of the main findings or conclusions"
)

# Default fields to extract (users can override this)
DEFAULT_FIELDS <- c("title", "author", "year", "state", "key_findings")

# Prompt Template ----------------------------------------------------------

# System prompt for OpenAI API
SYSTEM_PROMPT <- "You are a research assistant specializing in extracting metadata from academic and policy documents. Extract the requested information accurately and concisely."

# Base prompt template (will be customized per document)
EXTRACTION_PROMPT_TEMPLATE <- "Extract the following metadata from this document:
{field_descriptions}

Provide your response as a valid JSON object with these exact keys: {field_names}

Document text:
{document_text}"

# Output Configuration -----------------------------------------------------

# Default output format
DEFAULT_OUTPUT_FORMAT <- "csv"  # Options: "csv" or "excel"

# Output filename prefix
OUTPUT_FILENAME_PREFIX <- "lit_review_results"
