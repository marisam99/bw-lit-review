# ==============================================================================
# Title:        Dependencies
# Description:  Centralized package loading for the PDF metadata extraction tool.
#               Checks for required packages and prompts for installation if needed.
# Output:       None (loads packages into environment)
# ==============================================================================

# Required Packages ------------------------------------------------------------

required_packages <- c(
  "tidyverse",  # Core data manipulation (includes dplyr, readr, purrr, etc.)
  "here",       # Project-relative paths
  "ellmer",     # LLM API interface with file upload support
  "jsonlite",   # JSON parsing
  "writexl",    # Write Excel files
  "dotenv"      # Load API keys from .env file
)

# Check for Missing Packages ---------------------------------------------------

missing_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]

if (length(missing_packages) > 0) {
  message("❌ Missing required packages:\n")
  message(paste("  -", missing_packages, collapse = "\n"))
  message("\n")

  response <- readline(prompt = "Install missing packages now? (y/n): ")

  if (tolower(response) == "y") {
    message("\n📦 Installing packages...\n")
    install.packages(missing_packages)
    message("\n✅ Installation complete!\n")
  } else {
    stop("❌ Cannot proceed without required packages. Please install them manually using:\n   install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
  }
}

# Load Packages ----------------------------------------------------------------

library(tidyverse)
library(here)
library(ellmer)
library(jsonlite)
library(writexl)
library(dotenv)

# API KEY Check ----------------------------------------------------------------

#' Load and validate OpenAI API key from environment
#'
#' Loads .env file and validates that OPENAI_API_KEY is present and non-empty.
#' @return Character string with API key, or stops with error if not found
load_api_key <- function() {
  # Load .env file if it exists
  env_path <- here(".env")
  if (file.exists(env_path)) {
    load_dot_env(env_path)
  } else {
    stop("❌ .env file not found. Please create one based on .env.example and add your OPENAI_API_KEY")
  }

  # Get API key from environment
  api_key <- Sys.getenv("OPENAI_API_KEY")

  # Validate API key exists and is not empty
  if (api_key == "" || is.null(api_key)) {
    stop("❌ OPENAI_API_KEY not found in .env file. Please add your OpenAI API key")
  }

  # Basic format validation (OpenAI keys typically start with "sk-")
  if (!grepl("^sk-", api_key)) {
    warning("⚠️  API key format looks unusual. OpenAI keys typically start with 'sk-'")
  }

  return(api_key)
}