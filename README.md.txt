# Citation

Mortelmans, J. (2026). jonasmortelmansvliz/ImagingValidationApp: v1.0.1 (v1.0.1). Zenodo. https://doi.org/10.5281/zenodo.18429119



# ImagingValidationApp

**A Shiny-based tool for manual labeling of plankton images from the Pi-10 Plankton Imager.**

---

## Overview

`ImagingValidationApp` is an interactive Shiny application designed to:

- Browse `.tif` plankton images in subfolders.
- Select images and assign labels based on taxonomy.
- Track progress for each subfolder and overall dataset.
- Export validated labels to CSV files for downstream analysis.

The app dynamically generates label buttons based on a taxonomy file and color-codes them according to type (e.g., detritus, phytoplankton, copepod).

---

## Features

- **Dynamic taxonomy buttons**: Buttons are generated from `taxonomy.csv`, with type-specific colors.
- **Progress tracking**: Overall dataset and per-subfolder progress bars with a playful copepod icon.
- **Caching**: Efficient loading of `.tif` images using base64 encoding.
- **Export**: Save labeled datasets to CSV files.
- **Validate All**: Option to validate all images in a folder with a single click.
- **User tracking**: Labels are saved along with the username for multiple annotators.

---

## Installation

1. Clone this repository:

```bash
git clone https://github.com/jonasmortelmansvliz/ImagingValidationApp.git
