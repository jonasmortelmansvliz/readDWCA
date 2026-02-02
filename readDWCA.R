#### AUTHOR: Jonas Mortelmans
#### VERSION: V1.0.03

rm(list = ls())

source("./config/config.R")  
setwd(BASE_DIR)

# Load necessary libraries
library(dplyr)
library(tidyr)
library(httr)
library(ggplot2)
library(tools)

# Base URLs for the latest DwC-A datasets
datasets <- list(
  zoo = "https://ipt.vliz.be/upload/archive.do?r=lifewatch_zooplankton",
  phyto = "https://ipt.vliz.be/upload/archive.do?r=fyto"
)

# Ensure 'data' and 'output' folders exist
data_dir <- file.path(BASE_DIR, "data")
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# Helper function to download latest DwC-A with versioned filename
download_dwca <- function(url, data_dir) {
  # HEAD request to get actual filename from IPT
  res <- HEAD(url, followlocation = TRUE)
  hdr <- headers(res)
  filename <- sub(".*filename=\"([^\"]+)\".*", "\\1", hdr$`content-disposition`)
  
  if (is.na(filename) || filename == "") {
    # fallback name
    filename <- paste0("dwca-", basename(url), "-latest.zip")
  }
  
  zip_file_path <- file.path(data_dir, filename)
  GET(url, write_disk(zip_file_path, overwrite = TRUE))
  return(zip_file_path)
}

# Function to process a DwC-A ZIP into a cleaned CSV
process_dwca <- function(zip_file_path) {
  # Clear extraction folder
  if (dir.exists(EXTRACT_DIR)) unlink(EXTRACT_DIR, recursive = TRUE, force = TRUE)
  dir.create(EXTRACT_DIR, recursive = TRUE, showWarnings = FALSE)
  
  # Unzip
  unzip(zip_file_path, exdir = EXTRACT_DIR)
  
  # Read main tables
  event_df <- read.table(file.path(EXTRACT_DIR, "event.txt"), header = TRUE, sep = "\t", quote = "")
  occurrence_df <- read.table(file.path(EXTRACT_DIR, "occurrence.txt"), header = TRUE, sep = "\t", quote = "")
  extended_measures_df <- read.table(file.path(EXTRACT_DIR, "extendedmeasurementorfact.txt"), header = TRUE, sep = "\t", quote = "")
  
  # Clean extended measures
  extended_measures_df <- extended_measures_df[
    extended_measures_df$occurrenceID != "" &
      extended_measures_df$measurementType != "Development stage of biological entity specified elsewhere",
    c("measurementValue", "measurementType", "occurrenceID")
  ]
  extended_measures_df$measurementType <- NULL
  
  # Clean occurrence data
  occurrence_df <- occurrence_df[, !names(occurrence_df) %in% c("modified", "basisOfRecord", "occurrenceStatus", "scientificNameID")]
  
  # Split occurrenceID to extract full scientific name
  occurrence_df$split_before_sub <- sub("sub.*", "", occurrence_df$occurrenceID)
  occurrence_df$split_after_sub <- sub(".*sub", "", occurrence_df$occurrenceID)
  occurrence_df$split_before_subv <- sub("IDTA.*", "", occurrence_df$split_before_sub)
  occurrence_df$split_after_subv <- sub(".*IDTA", "", occurrence_df$split_before_sub)
  occurrence_df$split_before_sub <- NULL
  occurrence_df$split_after_sub <- NULL
  occurrence_df$split_before_subv <- NULL
  
  occurrence_df$split_after_subv <- gsub("[0-9]", "", occurrence_df$split_after_subv)
  occurrence_df$ScientificNameFull <- gsub("^_|_$", "", occurrence_df$split_after_subv)
  occurrence_df$split_after_subv <- NULL
  
  # Merge tables
  merged_df <- merge(extended_measures_df, occurrence_df, by = "occurrenceID", all.x = TRUE)
  final_df <- merge(merged_df, event_df, by = "eventID", all.x = TRUE)
  
  # Remove unnecessary columns
  final_df <- final_df[, !(names(final_df) %in% c(
    "country", "countryCode", "waterBody", "ownerInstitutionCode", "accessRights",
    "rightsHolder", "language", "id.y", "identificationReferences",
    "identificationVerificationStatus", 'type', 'associatedMedia'
  ))]
  
  # Convert eventDate
  final_df$eventDate <- as.Date(final_df$eventDate, format="%Y-%m-%dT%H:%MZ")
  
  # Save CSV
  zip_file_name <- tools::file_path_sans_ext(basename(zip_file_path))
  output_path <- file.path(OUTPUT_DIR, paste0(zip_file_name, ".csv"))
  write.csv(final_df, output_path, row.names = FALSE)
  
  # Cleanup extraction folder
  file.remove(list.files(EXTRACT_DIR, full.names = TRUE))
  
  cat("Processed and saved:", output_path, "\n")
  return(final_df)
}

# Loop through both datasets
final_data <- list()
for (ds in names(datasets)) {
  zip_path <- download_dwca(datasets[[ds]], data_dir)
  final_data[[ds]] <- process_dwca(zip_path)
}

# Optional: quick timeline plots for both
for (ds in names(final_data)) {
  ggplot(final_data[[ds]], aes(x = eventDate)) +
    geom_histogram(binwidth = 30, fill = "blue", color = "black", alpha = 0.7) +
    geom_density(aes(y = ..density..), color = "red", size = 1) +
    labs(title = paste0("Timeline of Events: ", ds), x = "Event Date", y = "Count") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
