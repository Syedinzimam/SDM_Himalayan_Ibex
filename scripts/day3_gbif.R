# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 3 - GBIF Occurrence Data Download
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(rgbif)
library(dplyr)
library(sf)
library(ggplot2)
library(rnaturalearth)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== DOWNLOADING HIMALAYAN IBEX DATA FROM GBIF ===\n\n")

# Species information
species_name <- "Capra sibirica"
cat("Species:", species_name, "\n")
cat("Common Name: Himalayan Ibex\n\n")

# Define study area extent (Southeast Asia focus)
# Coordinates: [min_lon, min_lat, max_lon, max_lat]
study_extent <- c(60, 25, 105, 45)  # Covers Pakistan, Afghanistan, India, Nepal, Bhutan, Tibet

cat("Study Area Extent:\n")
cat("  Longitude:", study_extent[1], "to", study_extent[3], "\n")
cat("  Latitude:", study_extent[2], "to", study_extent[4], "\n\n")

# Download occurrence data from GBIF
cat("Downloading data from GBIF...\n")
cat("This may take a few minutes...\n\n")

# Try to download with error handling
occurrences <- NULL

tryCatch({
  # Create WKT polygon for study area
  wkt_polygon <- paste0("POLYGON((", 
                        study_extent[1], " ", study_extent[2], ",",
                        study_extent[3], " ", study_extent[2], ",",
                        study_extent[3], " ", study_extent[4], ",",
                        study_extent[1], " ", study_extent[4], ",",
                        study_extent[1], " ", study_extent[2], "))")
  
  gbif_data <- occ_data(
    scientificName = species_name,
    hasCoordinate = TRUE,
    limit = 5000,
    geometry = wkt_polygon
  )
  
  occurrences <- gbif_data$data
  
  # If no data with geometry, try without
  if (is.null(occurrences) || nrow(occurrences) == 0) {
    cat("⚠ No data found with spatial filter. Trying without geometry...\n\n")
    gbif_data <- occ_data(
      scientificName = species_name,
      hasCoordinate = TRUE,
      limit = 5000
    )
    occurrences <- gbif_data$data
  }
  
}, error = function(e) {
  cat("✗ Error connecting to GBIF:\n")
  cat("  ", conditionMessage(e), "\n\n")
  cat("ALTERNATIVE OPTIONS:\n")
  cat("1. Check your internet connection\n")
  cat("2. Download data manually from: https://www.gbif.org/species/2441363\n")
  cat("3. Save as CSV and place in: data/raw/gbif_manual_download.csv\n\n")
  cat("Script will stop here. Re-run after internet is restored or manual download.\n")
})

# Stop if no data
if (is.null(occurrences)) {
  stop("No occurrence data available. Please check internet connection or download manually.")
}

cat("✓ Downloaded", nrow(occurrences), "occurrence records\n\n")

# Initial data cleaning
cat("=== DATA CLEANING ===\n\n")

# Select relevant columns
occ_clean <- occurrences %>%
  select(
    species = species,
    longitude = decimalLongitude,
    latitude = decimalLatitude,
    year = year,
    month = month,
    basisOfRecord,
    coordinateUncertaintyInMeters,
    country,
    locality,
    occurrenceID
  )

cat("Initial records:", nrow(occ_clean), "\n")

# Remove records with missing coordinates
occ_clean <- occ_clean %>%
  filter(!is.na(longitude) & !is.na(latitude))

# Filter to study area extent
occ_clean <- occ_clean %>%
  filter(longitude >= study_extent[1] & longitude <= study_extent[3] &
           latitude >= study_extent[2] & latitude <= study_extent[4])

cat("After removing NA coordinates:", nrow(occ_clean), "\n")
cat("After filtering to study area:", nrow(occ_clean), "\n")

# Remove duplicates based on coordinates
occ_clean <- occ_clean %>%
  distinct(longitude, latitude, .keep_all = TRUE)

cat("After removing duplicate coordinates:", nrow(occ_clean), "\n")

# Remove records with high coordinate uncertainty (>10km)
occ_clean <- occ_clean %>%
  filter(is.na(coordinateUncertaintyInMeters) | coordinateUncertaintyInMeters <= 10000)

cat("After filtering coordinate uncertainty:", nrow(occ_clean), "\n\n")

# Save raw data (convert lists to characters first)
occurrences_save <- occurrences
list_cols <- sapply(occurrences_save, is.list)
occurrences_save[list_cols] <- lapply(occurrences_save[list_cols], as.character)

write.csv(occurrences_save, "data/raw/gbif_raw_data.csv", row.names = FALSE)
cat("✓ Raw data saved to: data/raw/gbif_raw_data.csv\n")

# Save cleaned data
write.csv(occ_clean, "data/processed/occurrence_cleaned.csv", row.names = FALSE)
cat("✓ Cleaned data saved to: data/processed/occurrence_cleaned.csv\n\n")

# Summary statistics
cat("=== SUMMARY STATISTICS ===\n\n")
cat("Total occurrence points:", nrow(occ_clean), "\n")
cat("Date range:", min(occ_clean$year, na.rm = TRUE), "-", 
    max(occ_clean$year, na.rm = TRUE), "\n")
cat("\nRecords by country:\n")
print(table(occ_clean$country))

cat("\n\nRecords by basis:\n")
print(table(occ_clean$basisOfRecord))

# Create quick visualization
cat("\n\n=== CREATING VISUALIZATION ===\n")

# Get world map
world <- ne_countries(scale = "medium", returnclass = "sf")

# Plot occurrences
p <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_point(data = occ_clean, aes(x = longitude, y = latitude), 
             color = "red", size = 2, alpha = 0.6) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "Himalayan Ibex (Capra sibirica) Occurrences",
       subtitle = paste("GBIF Data -", nrow(occ_clean), "records"),
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

# Save plot
ggsave("outputs/maps/occurrence_map_raw.png", p, width = 10, height = 8, dpi = 300)
cat("✓ Map saved to: outputs/maps/occurrence_map_raw.png\n")

# Display plot
print(p)

cat("\n=== DAY 3 COMPLETE ===\n")
cat("Next: Run Day 4 script for environmental data download\n")
