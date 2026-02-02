#### PATH CONFIGURATION FILE
#### AUTHOR: Jonas Mortelmans

# Base project directory (optional but very useful)
BASE_DIR <- "~/R/readDWCA"

# Input
ZIP_DWCA_ZOOPLANKTON <- file.path(BASE_DIR, "data/dwca-lifewatch_zooplankton-v1.71.zip")
# ZIP_DWCA_PHYTO <- file.path(BASE_DIR, "data/dwca-fyto-v1.53.zip")

# Working directories
EXTRACT_DIR  <- file.path(BASE_DIR, "temp-extract")
OUTPUT_DIR    <- file.path(BASE_DIR, "output")
