####AUTHOR: Jonas Mortelmans
####VERSION: V1.0.0

rm(list = ls())

source("./config/config.R")  
setwd(BASE_DIR)

# Load necessary libraries
library(dplyr)
library(tidyr)

# Define the path to the ZIP file and the extraction location
zip_file_path <- ZIP_DWCA_ZOOPLANKTON

file.remove(list.files(EXTRACT_DIR, full.names = TRUE))
file.remove(list.files(OUTPUT_DIR, full.names = TRUE))

# Unzip the file
unzip(zip_file_path, exdir = EXTRACT_DIR)

# Read the three main data files into data frames
event_df <- read.table(file.path(EXTRACT_DIR, "event.txt"), header = TRUE, sep = "\t", quote = "")
occurrence_df <- read.table(file.path(EXTRACT_DIR, "occurrence.txt"), header = TRUE, sep = "\t", quote = "")
extended_measures_df <- read.table(file.path(EXTRACT_DIR, "extendedmeasurementorfact.txt"), header = TRUE, sep = "\t", quote = "")


extended_measures_df <- extended_measures_df[extended_measures_df$occurrenceID != "" & 
                                      extended_measures_df$measurementType != "Development stage of biological entity specified elsewhere", 
                                    c("measurementValue", "measurementType", "occurrenceID")]
extended_measures_df$measurementType <- NULL



occurrence_df <- occurrence_df[, !names(occurrence_df) %in% c("modified", "basisOfRecord", "occurrenceStatus", "scientificNameID")]
head(occurrence_df,20)

# Split the occurrenceID column into two parts based on the first occurrence of 'sub'
occurrence_df$split_before_sub <- sub("sub.*", "", occurrence_df$occurrenceID)  # Part before 'sub'
occurrence_df$split_after_sub <- sub(".*sub", "", occurrence_df$occurrenceID)   # Part after 'sub'

occurrence_df$split_before_subv <- sub("IDTA.*", "", occurrence_df$split_before_sub)  # Part before 'sub'
occurrence_df$split_after_subv <- sub(".*IDTA", "", occurrence_df$split_before_sub)   # Part after 'sub'
occurrence_df$split_before_sub<-NULL
occurrence_df$split_after_sub<-NULL
occurrence_df$split_before_subv<-NULL

occurrence_df$split_after_subv <- gsub("[0-9]", "", occurrence_df$split_after_subv)
occurrence_df$ScientificNameFull <- gsub("^_|_$", "", occurrence_df$split_after_subv)
occurrence_df$split_after_subv <- NULL

merged_df <- merge(extended_measures_df, occurrence_df, by = "occurrenceID", all.x = TRUE)


final_df <- merge(merged_df, event_df, by = "eventID", all.x = TRUE)
final_df <- final_df[, !(names(final_df) %in% c("country", "countryCode", "waterBody", 
                                                "ownerInstitutionCode", "accessRights", 
                                                "rightsHolder", "language", "id.y", "identificationReferences", "identificationVerificationStatus", 'type', 'associatedMedia'))]
str(final_df)



# Convert the eventDate column to Date type
final_df$eventDate <- as.Date(final_df$eventDate, format="%Y-%m-%dT%H:%MZ")

# Plot the timeline of events
library(ggplot2)


ggplot(final_df, aes(x = eventDate)) +
  geom_histogram(binwidth = 30, fill = "blue", color = "black", alpha = 0.7) +
  geom_density(aes(y = ..density..), color = "red", size = 1) +
  labs(title = "Timeline of Events", x = "Event Date", y = "Count") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# calanoida_df <- final_df[grep("Calanoida", final_df$scientificName), ]
# calanoida_df$measurementValue <- as.numeric(calanoida_df$measurementValue)
# ggplot(calanoida_df, aes(x = eventDate, y = measurementValue)) +
#   geom_point(color = "red") +  # Add points to show individual measurements
#   labs(title = "Measurement Values of Calanoida Over Time", x = "Event Date", y = "Measurement Value") +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1))


zip_file_name <- tools::file_path_sans_ext(basename(zip_file_path))
output_path <- file.path("output", paste0(zip_file_name, ".csv"))
write.csv(final_df, output_path, row.names = FALSE)
cat("The final dataframe has been saved as:", output_path)

file.remove(list.files(EXTRACT_DIR, full.names = TRUE))

