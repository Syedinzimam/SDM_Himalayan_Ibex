# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 4 - WorldClim Environmental Data Download
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(terra)
library(dismo)
library(sf)
library(ggplot2)
library(viridis)

# Install and load geodata package
if (!require("geodata")) {
  install.packages("geodata")
  library(geodata)
} else {
  library(geodata)
}

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== DOWNLOADING WORLDCLIM BIOCLIMATIC VARIABLES ===\n\n")

# Load occurrence data
occ_data <- read.csv("data/processed/occurrence_cleaned.csv")
cat("Loaded", nrow(occ_data), "occurrence records\n\n")

# Define study area extent with buffer
study_extent <- c(60, 25, 105, 45)
cat("Study Area Extent:\n")
cat("  Longitude:", study_extent[1], "to", study_extent[3], "\n")
cat("  Latitude:", study_extent[2], "to", study_extent[4], "\n\n")

# Download WorldClim data
# Resolution: 2.5 minutes (~5km at equator)
cat("Downloading WorldClim bioclimatic variables...\n")
cat("Resolution: 2.5 arc-minutes (~5km)\n")
cat("This will take several minutes...\n\n")

# Download bioclimatic variables using geodata
worldclim_data <- worldclim_global(
  var = 'bio',
  res = 2.5,
  path = 'data/environmental/'
)

cat("✓ WorldClim data downloaded successfully!\n\n")

# Crop to study area
cat("Cropping to study area...\n")
extent_box <- ext(study_extent[1], study_extent[3], 
                  study_extent[2], study_extent[4])

bioclim_cropped <- crop(worldclim_data, extent_box)

cat("✓ Data cropped to study area\n\n")

# Save cropped rasters
cat("Saving cropped bioclimatic layers...\n")
writeRaster(bioclim_cropped, 
            filename = "data/environmental/bioclim_cropped.tif",
            overwrite = TRUE)

cat("✓ Cropped data saved\n\n")

# Bioclimatic variables information
bioclim_names <- c(
  "BIO1 = Annual Mean Temperature",
  "BIO2 = Mean Diurnal Range",
  "BIO3 = Isothermality",
  "BIO4 = Temperature Seasonality",
  "BIO5 = Max Temperature of Warmest Month",
  "BIO6 = Min Temperature of Coldest Month",
  "BIO7 = Temperature Annual Range",
  "BIO8 = Mean Temperature of Wettest Quarter",
  "BIO9 = Mean Temperature of Driest Quarter",
  "BIO10 = Mean Temperature of Warmest Quarter",
  "BIO11 = Mean Temperature of Coldest Quarter",
  "BIO12 = Annual Precipitation",
  "BIO13 = Precipitation of Wettest Month",
  "BIO14 = Precipitation of Driest Month",
  "BIO15 = Precipitation Seasonality",
  "BIO16 = Precipitation of Wettest Quarter",
  "BIO17 = Precipitation of Driest Quarter",
  "BIO18 = Precipitation of Warmest Quarter",
  "BIO19 = Precipitation of Coldest Quarter"
)

cat("=== BIOCLIMATIC VARIABLES ===\n\n")
cat(paste(bioclim_names, collapse = "\n"))
cat("\n\n")

# Extract environmental values at occurrence points
cat("Extracting environmental values at occurrence locations...\n")
coords <- occ_data[, c("longitude", "latitude")]
env_values <- extract(bioclim_cropped, coords)

# Add to occurrence data
occ_with_env <- cbind(occ_data, env_values)

# Remove any points with NA environmental values
occ_with_env <- na.omit(occ_with_env)

cat("✓ Environmental values extracted\n")
cat("Records with complete environmental data:", nrow(occ_with_env), "\n\n")

# Save occurrence data with environmental values
write.csv(occ_with_env, 
          "data/processed/occurrence_with_environment.csv", 
          row.names = FALSE)
cat("✓ Data saved to: data/processed/occurrence_with_environment.csv\n\n")

# Create visualization of key variables
cat("Creating environmental data visualization...\n\n")

# Plot 4 key variables
key_vars <- c(1, 12, 5, 6)  # BIO1, BIO12, BIO5, BIO6
var_names <- c("Annual Mean Temp", "Annual Precip", 
               "Max Temp Warmest Month", "Min Temp Coldest Month")

png("outputs/maps/bioclim_variables.png", width = 12, height = 10, 
    units = "in", res = 300)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 6))

for (i in 1:4) {
  plot(bioclim_cropped[[key_vars[i]]], 
       main = var_names[i],
       col = viridis(100))
  points(occ_data$longitude, occ_data$latitude, 
         pch = 20, cex = 0.5, col = "red")
}

dev.off()

cat("✓ Visualization saved to: outputs/maps/bioclim_variables.png\n\n")

# Summary statistics
cat("=== ENVIRONMENTAL DATA SUMMARY ===\n\n")
cat("Number of bioclimatic layers:", nlyr(bioclim_cropped), "\n")
cat("Spatial resolution:", res(bioclim_cropped), "degrees\n")
cat("Extent:", as.vector(ext(bioclim_cropped)), "\n")
cat("Coordinate system:", crs(bioclim_cropped, describe = TRUE)$name, "\n\n")

# Summary of environmental values at occurrence points
cat("Environmental conditions at occurrence locations:\n\n")

# Check number of columns in env_values
n_vars <- ncol(env_values)
cat("Number of environmental variables:", n_vars, "\n\n")

env_summary <- data.frame(
  Variable = colnames(env_values),
  Mean = round(colMeans(env_values, na.rm = TRUE), 2),
  SD = round(apply(env_values, 2, sd, na.rm = TRUE), 2),
  Min = round(apply(env_values, 2, min, na.rm = TRUE), 2),
  Max = round(apply(env_values, 2, max, na.rm = TRUE), 2)
)

print(env_summary)

# Save summary
write.csv(env_summary, "outputs/tables/environmental_summary.csv", 
          row.names = FALSE)
cat("\n✓ Summary saved to: outputs/tables/environmental_summary.csv\n")

cat("\n=== DAY 4 COMPLETE ===\n")
cat("Next: Run Day 5 script for variable selection & correlation analysis\n")
