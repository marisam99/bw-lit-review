# ==============================================================================
# Title:        Dependencies
# Description:  Centralized package loading for the PDF metadata extraction tool.
#               Load this file at the start of any script that uses these packages.
# Output:       None (loads packages into environment)
# ==============================================================================

# Core data manipulation
library(tidyverse)  # Includes dplyr, readr, purrr, etc.

# Path management
library(here)       # Project-relative paths

# API and JSON handling
library(ellmer)     # LLM API interface with file upload support
library(jsonlite)   # JSON parsing

# Excel output
library(writexl)    # Write Excel files

# Environment variables
library(dotenv)     # Load API keys from .env file
