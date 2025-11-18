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
