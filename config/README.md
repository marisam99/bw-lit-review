# Configuration Guide

This directory contains configuration files that control how the PDF metadata extraction tool behaves. You can modify these settings to customize the tool for your specific needs.

## Configuration Files

### `dependencies.R`
Manages all R package dependencies for the project. Automatically checks for and offers to install missing packages when you run the tool.

**Required packages:**
- `tidyverse` - Core data manipulation
- `here` - Project-relative paths
- `ellmer` - LLM API interface with file upload support
- `jsonlite` - JSON parsing
- `writexl` - Excel file writing
- `dotenv` - Environment variable management

**Note:** You generally don't need to modify this file unless you're adding new functionality that requires additional packages.

### `settings.R`
Contains all customizable settings including OpenAI API configuration, metadata fields, prompts, and batch processing parameters.

---

## OpenAI Model Configuration

### Available Models

The tool uses OpenAI's vision-capable models to read PDFs directly. Current options:

| Model | Speed | Cost | Best For | Reasoning Capability |
|-------|-------|------|----------|---------------------|
| `gpt-5.1` | Medium | High | Complex documents, nuanced extraction | Excellent (configurable) |
| `gpt-5` | Medium | High | Standard research documents | Very Good |
| `gpt-5-mini` | Fast | Low | Simple documents, tight budgets | Good |
| `gpt-5-nano` | Very Fast | Very Low | High-volume processing | Basic |

**Default:** `gpt-5.1`

### GPT-5.1 Specific Parameters

GPT-5.1 uses the Responses API and offers additional configuration:

**Reasoning Effort** (`REASONING_EFFORT`)
Controls how deeply the model analyzes the document:
- `"none"` - Fastest, minimal analysis (default)
- `"minimal"` - Light reasoning
- `"low"` - Basic analysis
- `"medium"` - Balanced analysis
- `"high"` - Deep analysis (slower, more thorough)

**Verbosity** (`VERBOSITY`)
Controls output detail level:
- `"low"` - Concise responses
- `"medium"` - Balanced (default)
- `"high"` - Detailed responses

### Model Selection Guidance

**Use GPT-5.1 with high reasoning when:**
- Documents have complex tables or figures
- Metadata is scattered throughout the document
- You need high accuracy on nuanced information

**Use GPT-5-mini when:**
- Documents follow standard academic paper format
- Processing large batches (50+ files) on a budget
- Speed is more important than perfect accuracy

**To change models:** Edit `OPENAI_MODEL` in `settings.R`

```r
# In config/settings.R
OPENAI_MODEL <- "gpt-5-mini"  # Change from default gpt-5.1
```

---

## Metadata Field Configuration

### Default Fields

The tool extracts these fields by default:
- `title` - Full document title
- `authors` - Primary author(s)
- `organization` - Publishing organization
- `year` - Publication year
- `state` - U.S. state(s) mentioned (if applicable)
- `key_findings` - 2-3 sentence summary of main findings

### Adding Custom Fields

1. **Define the field** in `METADATA_FIELDS` with a description:
```r
METADATA_FIELDS <- list(
  title = "The full title of the document",
  authors = "Primary author(s)",
  # ... existing fields ...
  methodology = "Research methodology used in the study",  # New field
  sample_size = "Number of participants or data points"    # New field
)
```

2. **Add to default extraction** (optional):
```r
DEFAULT_FIELDS <- c(
  "title", "authors", "organization", "year", "state", "key_findings",
  "methodology", "sample_size"  # Add new fields
)
```

**OR** specify custom fields when calling the function:
```r
# Extract only specific fields
result <- process_pdf_batch(fields = c("title", "authors", "methodology"))
```

### Field Description Best Practices

- Be specific about what you want extracted
- Include examples if the field might be ambiguous
- Specify format requirements (e.g., "comma-separated list")
- Indicate if `N/A` is acceptable for missing data

**Example:**
```r
funding_source = "Primary funding organization(s). List up to 3, comma-separated. Use N/A if not mentioned."
```

---

## Batch Processing Configuration

### Rate Limiting

**`BATCH_DELAY_SECONDS`** - Time to wait between API requests (default: `0.5`)

- Prevents hitting OpenAI rate limits
- Adjust based on your API tier:
  - Free tier: Use `1.0` second or higher
  - Standard tier: Use `0.5` seconds (default)
  - High-volume tier: Can reduce to `0.2` seconds

**Example:**
```r
BATCH_DELAY_SECONDS <- 1.0  # More conservative for free tier
```

### Retry Configuration

**`MAX_RETRY_ATTEMPTS`** - Number of times to retry failed requests (default: `3`)

- Automatically retries transient failures (timeouts, rate limits, temporary server errors)
- Uses exponential backoff (delays double with each retry)
- Non-retryable errors (invalid files, malformed PDFs) fail immediately

**When to adjust:**
- Increase to `5` if you have unstable network connection
- Decrease to `1` if you want faster failure on problem files

### Timeout Configuration

**`API_TIMEOUT_SECONDS`** - Maximum wait time for API response (default: `120`)

- Large PDFs (20+ MB) may need longer timeouts
- Complex documents with many pages may need more time

**Recommended settings by file size:**
- Small files (<5 MB): `60` seconds
- Medium files (5-20 MB): `120` seconds (default)
- Large files (20+ MB): `180` seconds

---

## Prompt Customization

### System Prompt

**`SYSTEM_PROMPT`** sets the AI's role and behavior:

```r
SYSTEM_PROMPT <- "You are a research assistant specializing in extracting metadata from academic and policy documents. Extract the requested information accurately and concisely."
```

**Customize for different document types:**
- Legal documents: "...specializing in legal document analysis..."
- Technical reports: "...specializing in technical documentation..."
- Medical literature: "...specializing in medical research papers..."

### Extraction Prompt Template

**`EXTRACTION_PROMPT_TEMPLATE`** defines how the AI should extract data.

**Key placeholders:**
- `{field_descriptions}` - Auto-populated with field definitions
- `{field_names}` - Auto-populated with field names for JSON structure

**Customization example:**
```r
EXTRACTION_PROMPT_TEMPLATE <- "Extract the following metadata from the uploaded PDF document:
{field_descriptions}

IMPORTANT INSTRUCTIONS:
- Read ALL pages including appendices
- Extract exact quotes for key findings
- Use ISO date format (YYYY-MM-DD) for dates
- If uncertain, note confidence level in parentheses

Provide your response as valid JSON: {field_names}"
```

---

## Environment Variables

### Required: OpenAI API Key

The tool requires an OpenAI API key stored in a `.env` file in the project root.

**Setup steps:**

1. Copy the example file:
```bash
cp .env.example .env
```

2. Edit `.env` and add your API key:
```
OPENAI_API_KEY=sk-your-actual-api-key-here
```

3. Keep `.env` secure - it's automatically git-ignored

**Getting an API key:**
- Sign up at https://platform.openai.com
- Navigate to API Keys section
- Create new secret key
- Copy immediately (you won't see it again)

**API key format:**
- Should start with `sk-`
- Usually 48+ characters long
- Keep confidential - never commit to git or share publicly

### Optional: Additional Environment Variables

You can add other environment variables to `.env` if needed:

```
OPENAI_API_KEY=sk-your-key-here
OUTPUT_DIRECTORY=/path/to/save/results
MAX_FILE_SIZE_MB=50
```

Access in R code:
```r
output_dir <- Sys.getenv("OUTPUT_DIRECTORY", default = "output")
```

---

## Recommended Settings by Use Case

### Use Case 1: Quick Literature Review (Speed Priority)

```r
# In config/settings.R
OPENAI_MODEL <- "gpt-5-mini"
REASONING_EFFORT <- "none"
VERBOSITY <- "low"
BATCH_DELAY_SECONDS <- 0.5
MAX_RETRY_ATTEMPTS <- 2
API_TIMEOUT_SECONDS <- 60
DEFAULT_FIELDS <- c("title", "authors", "year", "key_findings")
```

**Best for:** Scanning 50+ papers quickly to identify relevant research

---

### Use Case 2: Detailed Policy Analysis (Accuracy Priority)

```r
# In config/settings.R
OPENAI_MODEL <- "gpt-5.1"
REASONING_EFFORT <- "high"
VERBOSITY <- "high"
BATCH_DELAY_SECONDS <- 1.0
MAX_RETRY_ATTEMPTS <- 3
API_TIMEOUT_SECONDS <- 180
DEFAULT_FIELDS <- c("title", "authors", "organization", "year", "state",
                   "key_findings", "methodology", "recommendations")
```

**Best for:** Comprehensive analysis of 10-20 policy documents with complex content

---

### Use Case 3: Budget-Conscious Processing (Cost Priority)

```r
# In config/settings.R
OPENAI_MODEL <- "gpt-5-nano"
REASONING_EFFORT <- "none"  # N/A for nano, but doesn't hurt
VERBOSITY <- "low"
BATCH_DELAY_SECONDS <- 0.3  # Faster processing
MAX_RETRY_ATTEMPTS <- 1     # Fewer retries
API_TIMEOUT_SECONDS <- 45
DEFAULT_FIELDS <- c("title", "authors", "year")  # Minimal fields
```

**Best for:** Large-scale processing (100+ files) where rough metadata is sufficient

---

### Use Case 4: State-Specific Research

```r
# In config/settings.R
OPENAI_MODEL <- "gpt-5.1"
REASONING_EFFORT <- "medium"
VERBOSITY <- "medium"

# Customize system prompt
SYSTEM_PROMPT <- "You are a research assistant specializing in U.S. state policy documents. Pay special attention to geographic scope and state-specific information."

# Customize extraction prompt
EXTRACTION_PROMPT_TEMPLATE <- "Extract the following metadata from the uploaded PDF document:
{field_descriptions}

SPECIAL INSTRUCTIONS FOR STATE FIELD:
- List ALL U.S. states mentioned in the document
- Include states in data, case studies, or examples
- Use two-letter abbreviations (CA, NY, TX)
- Separate multiple states with semicolons

Provide your response as valid JSON: {field_names}"

DEFAULT_FIELDS <- c("title", "authors", "organization", "year", "state",
                   "key_findings", "geographic_scope")
```

**Best for:** Research focused on state-level policies and programs

---

## Troubleshooting Configuration Issues

### Problem: API timeout errors

**Solution:** Increase `API_TIMEOUT_SECONDS`
```r
API_TIMEOUT_SECONDS <- 180  # Up from default 120
```

### Problem: Rate limit errors

**Solution:** Increase `BATCH_DELAY_SECONDS`
```r
BATCH_DELAY_SECONDS <- 2.0  # Up from default 0.5
```

### Problem: Poor extraction quality

**Solutions:**
1. Use a more powerful model: `OPENAI_MODEL <- "gpt-5.1"`
2. Increase reasoning: `REASONING_EFFORT <- "high"`
3. Improve field descriptions with examples
4. Customize extraction prompt with specific instructions

### Problem: Cost too high

**Solutions:**
1. Use cheaper model: `OPENAI_MODEL <- "gpt-5-mini"`
2. Reduce reasoning: `REASONING_EFFORT <- "none"`
3. Extract fewer fields
4. Process only essential documents

### Problem: Fields often return N/A

**Solutions:**
1. Improve field descriptions (be more specific)
2. Add examples to field definitions
3. Increase verbosity: `VERBOSITY <- "high"`
4. Check if information actually exists in your documents

---

## Advanced Configuration

### Multiple Configuration Profiles

Create different settings files for different projects:

```r
# config/settings_quick.R
OPENAI_MODEL <- "gpt-5-mini"
REASONING_EFFORT <- "none"
# ... quick settings ...

# config/settings_detailed.R
OPENAI_MODEL <- "gpt-5.1"
REASONING_EFFORT <- "high"
# ... detailed settings ...
```

Load the appropriate one:
```r
# In your script
source(here("config/settings_quick.R"))  # Or settings_detailed.R
```

### Dynamic Field Selection

Create field sets for different document types:

```r
# In config/settings.R
ACADEMIC_FIELDS <- c("title", "authors", "journal", "year", "methodology", "key_findings")
POLICY_FIELDS <- c("title", "organization", "year", "state", "recommendations", "key_findings")
REPORT_FIELDS <- c("title", "organization", "year", "executive_summary", "key_findings")

# Use in your script
result <- process_pdf_batch(fields = POLICY_FIELDS)
```

---

## Questions or Issues?

If you encounter configuration problems or need help customizing settings for your use case, contact the project maintainer (see main README for contact information).
