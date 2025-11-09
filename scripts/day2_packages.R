# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 2 - Package Installation & MaxEnt Setup
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== INSTALLING REQUIRED PACKAGES ===\n\n")

# List of required packages
packages <- c(
  "dismo",        # SDM modeling
  "raster",       # Raster data handling
  "rgbif",        # GBIF data access
  "sf",           # Spatial features
  "rJava",        # Java interface for MaxEnt
  "sp",           # Spatial data classes
  "rgdal",        # Geospatial data
  "maptools",     # Map tools
  "ggplot2",      # Visualization
  "viridis",      # Color palettes
  "rnaturalearth", # World maps
  "rnaturalearthdata", # Map data
  "tidyverse",    # Data manipulation
  "corrplot",     # Correlation plots
  "caret"         # Model evaluation
)

# Function to install and load packages
install_and_load <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# Install and load all packages
for (pkg in packages) {
  cat("Processing:", pkg, "...\n")
  install_and_load(pkg)
}

cat("\n✓ All packages installed successfully!\n\n")

# Check Java installation for MaxEnt
cat("=== CHECKING JAVA INSTALLATION ===\n")
tryCatch({
  library(rJava)
  .jinit()
  cat("✓ Java is properly configured\n")
}, error = function(e) {
  cat("✗ Java configuration issue:\n")
  cat("  Please install Java JDK 8 or higher\n")
  cat("  Download from: https://www.java.com/download/\n")
})

# MaxEnt setup instructions
cat("\n=== MAXENT SETUP INSTRUCTIONS ===\n")
cat("To use MaxEnt, you need to download maxent.jar:\n")
cat("1. Visit: https://biodiversityinformatics.amnh.org/open_source/maxent/\n")
cat("2. Download maxent.jar\n")
cat("3. Place it in:", system.file("java", package="dismo"), "\n")
cat("4. Run: file.copy('path/to/maxent.jar', system.file('java', package='dismo'))\n\n")

# Check if MaxEnt is available
maxent_path <- system.file("java", package = "dismo")
maxent_jar <- file.path(maxent_path, "maxent.jar")

if (file.exists(maxent_jar)) {
  cat("✓ MaxEnt is ready to use!\n")
} else {
  cat("⚠ MaxEnt not found. Please follow the instructions above.\n")
}

# Save package versions (only successfully installed ones)
installed_pkgs <- installed.packages()[, "Package"]
available_pkgs <- packages[packages %in% installed_pkgs]
if (length(available_pkgs) > 0) {
  pkg_info <- installed.packages()[available_pkgs, c("Package", "Version")]
  write.csv(pkg_info, "docs/package_versions.csv", row.names = FALSE)
}

cat("\n✓ Package versions saved to docs/package_versions.csv\n")
cat("\n=== PACKAGE SETUP COMPLETE ===\n")
cat("Next: Run Day 3 script for GBIF data download\n")