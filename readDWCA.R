#### AUTHOR: Jonas Mortelmans
#### VERSION: V1.0.02

rm(list = ls())

source("./config/config.R")  
setwd(BASE_DIR)

# Load necessary libraries
library(dplyr)
library(tidyr)
library(httr)
library(ggplot2)
library(tools)

# Base URL (latest DwC-A)
zoo <- "https://ipt.vliz.be/upload/archive.do?r=lifewatch_zooplankton"
phyt <- "https://ipt.vliz.be/upload/archive.do?r=fyto"


# Download to 'data' folder with version in filename
data_dir <- file.path(BASE_DIR, "data")
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# Make a HEAD request to get the filename from the server
res <- HEAD(latest_url, followlocation = TRUE)

# Extract filename from headers (Content-Disposition)
hdr <- headers(res)
filename <- sub(".*filename=\"([^\"]+)\".*", "\\1", hdr$`content-disposition`)
# Example filename: dwca-lifewatch_zooplankton-v1.81.zip

# If header parsing fails, fallback
if (is.na(filename) || filename == "") {
  filename <- "dwca-lifewatch_zooplankton-latest.zip"
}

zip_file_path <- file.path(data_dir, filename)

# Download the file
GET(latest_url, write_disk(zip_file_path, overwrite = TRUE))

cat("Downloaded DwC-A saved as:", zip_file_path, "\n")




# Prepare extraction and output directories
if (dir.exists(EXTRACT_DIR)) unlink(EXTRACT_DIR, recursive = TRUE, force = TRUE)
dir.create(EXTRACT_DIR, recursive = TRUE, showWarnings = FALSE)

if (dir.exists(OUTPUT_DIR)) unlink(OUTPUT_DIR, recursive = TRUE, force = TRUE)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Unzip the latest DwC-A
unzip(zip_file_path, exdir = EXTRACT_DIR)

# Read main data files
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

# Split occurrenceID
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

# Merge dataframes
merged_df <- merge(extended_measures_df, occurrence_df, by = "occurrenceID", all.x = TRUE)
final_df <- merge(merged_df, event_df, by = "eventID", all.x = TRUE)

# Remove unnecessary columns
final_df <- final_df[, !(names(final_df) %in% c(
  "country", "countryCode", "waterBody", "ownerInstitutionCode", "accessRights", 
  "rightsHolder", "language", "id.y", "identificationReferences", 
  "identificationVerificationStatus", 'type', 'associatedMedia'
))]

# Convert eventDate to Date type
final_df$eventDate <- as.Date(final_df$eventDate, format="%Y-%m-%dT%H:%MZ")

# Plot event timeline
ggplot(final_df, aes(x = eventDate)) +
  geom_histogram(binwidth = 30, fill = "blue", color = "black", alpha = 0.7) +
  geom_density(aes(y = ..density..), color = "red", size = 1) +
  labs(title = "Timeline of Events", x = "Event Date", y = "Count") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Save final dataframe
zip_file_name <- tools::file_path_sans_ext(basename(zip_file_path))
output_path <- file.path(OUTPUT_DIR, paste0(zip_file_name, ".csv"))
write.csv(final_df, output_path, row.names = FALSE)
cat("The final dataframe has been saved as:", output_path, "\n")

# Clean up extraction folder
file.remove(list.files(EXTRACT_DIR, full.names = TRUE))
