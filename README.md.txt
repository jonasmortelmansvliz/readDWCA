readDWCA

This repository contains an R script for reading, processing, and exporting Darwin Core Archive (DwC-A) datasets, with a focus on LifeWatch zooplankton imaging data from the Belgian part of the North Sea.

The script unzips a Darwin Core Archive, reads the core tables (event, occurrence, and extendedmeasurementorfact), performs data cleaning and filtering, derives taxonomic information from occurrence identifiers, merges all relevant tables, and exports a flat, analysis-ready CSV file.

All file paths are defined outside the main script using a configuration file to ensure portability and reproducibility across systems.

Usage

Place a Darwin Core Archive (.zip) file in the data/ directory.

Update the ZIP filename in config/config.R if necessary.

Run the script readDWCA.R in R.

The processed dataset is written to the export/ directory as a CSV file named after the input archive.

Dependencies

The script requires the following R packages:

dplyr

tidyr

ggplot2

Notes

Large input files and generated outputs are excluded from version control.
The workflow is intended for exploratory analysis and data preparation.

Author

Jonas Mortelmans
Flanders Marine Institute (VLIZ)