# ==============================================================================
# Title:        Dependencies
# Description:  Centralized package loading for the PDF metadata extraction tool.
#               Load this file at the start of any script that uses these packages.
# Output:       None (loads packages into environment)
# ==============================================================================

# Core data manipulation
library(tidyverse)  # Includes dplyr, readr, purrr, etc.

# API and JSON handling
library(httr2)      # Modern HTTP client for API calls
library(jsonlite)   # JSON parsing

# PDF processing
library(pdftools)   # Extract text from PDF files

# Excel output
library(writexl)    # Write Excel files

# Environment variables
library(dotenv)     # Load API keys from .env file
