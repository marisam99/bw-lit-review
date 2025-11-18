# ==============================================================================
# Title:        Settings and Configuration
# Description:  Centralized configuration for OpenAI API calls, metadata fields,
#               and default options. Modify these values to customize tool behavior
#               without changing core functions.
# Output:       None (defines constants and configuration variables)
# ==============================================================================

# OpenAI API Configuration -------------------------------------------------

# Model to use for extraction (must be vision-capable for direct PDF upload)
OPENAI_MODEL <- "gpt-5.1"  # Latest flagship model in GPT-5 family
# Other options: "gpt-5" (previous flagship), "gpt-5-mini" (cost-optimized), "gpt-5-nano" (high-throughput)
# NOTE: GPT-5.1 uses the Responses API (not Chat Completions API)

# GPT-5.1 specific parameters
REASONING_EFFORT <- "none"  # Options: "none" (fastest), "low", "medium", "high"
VERBOSITY_LEVEL <- "medium"  # Options: "low", "medium", "high"

# API parameters
API_MAX_TOKENS <- 1500  # Maximum tokens in response
API_TIMEOUT_SECONDS <- 120  # Request timeout (increased for large PDFs)

# Batch Processing Configuration -------------------------------------------

# Delay between API requests (in seconds) to avoid rate limits
BATCH_DELAY_SECONDS <- 0.5

# Number of retry attempts for failed API calls
MAX_RETRY_ATTEMPTS <- 3

# File size warning threshold (in MB)
FILE_SIZE_WARNING_MB <- 20

# Metadata Field Definitions -----------------------------------------------

# Available metadata fields that can be extracted
METADATA_FIELDS <- list(
  title = "The full title of the document",
  authors = "Primary author(s)",
  organization = "Publishing organization"
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
EXTRACTION_PROMPT_TEMPLATE <- "Extract the following metadata from the uploaded PDF document:
{field_descriptions}

Provide your response as a valid JSON object with these exact keys: {field_names}

Important notes:
- Read the entire document, including any tables, charts, or figures
- If a field is not found or not applicable, use "N/A"
- For the key_findings field, synthesize information from throughout the document"

# Output Configuration -----------------------------------------------------

# Default output format
DEFAULT_OUTPUT_FORMAT <- "csv"  # Options: "csv" or "excel"

# Output filename prefix
OUTPUT_FILENAME_PREFIX <- "lit_review_results"
