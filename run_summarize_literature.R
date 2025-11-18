# ==============================================================================
# Title:        Summarize Literature
# Description:  Sends requested PDF files to the OpenAI API to extract 
#               bibliographic metadata and key findings.
# Output:       Data frame with one row per PDF containing extracted metadata
# ==============================================================================

# Configs ----------------------------------------------------------------------

source(here("config/dependencies.R"))
source(here("config/settings.R"))
source(here("R/build_prompt.R"))
source(here("R/process_response.R"))
source(here("R/api_call_extraction.R"))

# Run Tool ---------------------------------------------------------------------

results <- extract_pdf_metadata()