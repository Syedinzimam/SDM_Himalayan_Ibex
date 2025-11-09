# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 8 - Binary Classification & Habitat Analysis
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(raster)
library(terra)
library(sf)
library(ggplot2)
library(rnaturalearth)
library(dplyr)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== BINARY HABITAT CLASSIFICATION & AREA ANALYSIS ===\n\n")

# Load MaxEnt model
maxent_model <- readRDS("outputs/models/maxent_model.rds")

# Load environmental layers
env_stack <- raster::stack("data/environmental/bioclim_selected.tif")
names(env_stack) <- paste0("bio", c(1, 2, 3, 4, 12, 15, 18, 19))

cat("✓ Model loaded\n")
cat("✓ Environmental layers loaded\n\n")

# Check if prediction exists and is valid
prediction_file <- "outputs/models/habitat_suitability.tif"
if (file.exists(prediction_file)) {
  prediction <- raster(prediction_file)
  pred_test <- values(prediction)[1:100]
  
  if (all(is.na(pred_test))) {
    cat("⚠ Existing prediction has NA values. Regenerating...\n\n")
    prediction <- predict(maxent_model, env_stack)
    writeRaster(prediction, prediction_file, overwrite = TRUE)
    cat("✓ New prediction generated and saved\n\n")
  } else {
    cat("✓ Valid prediction loaded\n\n")
  }
} else {
  cat("⚠ Prediction file not found. Generating...\n\n")
  prediction <- predict(maxent_model, env_stack)
  writeRaster(prediction, prediction_file, overwrite = TRUE)
  cat("✓ Prediction generated and saved\n\n")
}

# Check prediction values first
cat("Checking prediction values...\n")
pred_values <- values(prediction)
pred_values <- pred_values[!is.na(pred_values)]

cat("Prediction statistics:\n")
cat("  Min:", min(pred_values), "\n")
cat("  Max:", max(pred_values), "\n")
cat("  Mean:", mean(pred_values), "\n")
cat("  Median:", median(pred_values), "\n\n")

# Load threshold data
thresholds <- read.csv("outputs/tables/model_thresholds.csv")
cat("Available thresholds:\n")
print(thresholds)
cat("\n")

# Use median threshold or 0.5 if thresholds don't work
if (!is.na(thresholds$spec_sens[1]) && thresholds$spec_sens[1] > 0) {
  threshold_value <- thresholds$spec_sens[1]
  cat("Using spec_sens threshold:", round(threshold_value, 4), "\n\n")
} else {
  # Use median of prediction values
  threshold_value <- median(pred_values)
  cat("Using median threshold:", round(threshold_value, 4), "\n\n")
}

# Create binary habitat map
cat("Creating binary habitat classification...\n")
binary_habitat <- prediction >= threshold_value

cat("✓ Binary habitat map created\n\n")

# Save binary raster
writeRaster(binary_habitat, 
            "outputs/models/binary_habitat.tif",
            overwrite = TRUE)

# Calculate suitable habitat area
cat("=== HABITAT AREA CALCULATIONS ===\n\n")

# Get cell resolution and calculate area
cell_res <- res(prediction)  # Resolution in degrees
cat("Cell resolution:", cell_res, "degrees\n")

# Calculate cell area in km² (approximate)
# At latitude ~35° (middle of study area), 1 degree ≈ 91 km
lat_correction <- cos(35 * pi / 180)
cell_area_km2 <- (cell_res[1] * 111) * (cell_res[2] * 111 * lat_correction)
cat("Approximate cell area:", round(cell_area_km2, 2), "km²\n\n")

# Count suitable cells
suitable_cells <- cellStats(binary_habitat == 1, sum, na.rm = TRUE)
unsuitable_cells <- cellStats(binary_habitat == 0, sum, na.rm = TRUE)
cat("Suitable cells:", suitable_cells, "\n")
cat("Unsuitable cells:", unsuitable_cells, "\n")

total_suitable_area <- suitable_cells * cell_area_km2

cat("Suitable habitat area:", round(total_suitable_area, 2), "km²\n\n")

# Calculate percentage of study area
total_cells <- cellStats(!is.na(prediction), sum, na.rm = TRUE)
percent_suitable <- (suitable_cells / total_cells) * 100

cat("Total cells in study area:", total_cells, "\n")
cat("Percentage of study area suitable:", round(percent_suitable, 2), "%\n\n")

# Create binary habitat map visualization
cat("Creating binary habitat map...\n")

# Get world map
world <- ne_countries(scale = "medium", returnclass = "sf")
study_extent <- c(60, 25, 105, 45)

# Convert binary raster to dataframe for ggplot
binary_df <- as.data.frame(binary_habitat, xy = TRUE)
colnames(binary_df) <- c("x", "y", "suitable")
binary_df <- binary_df[!is.na(binary_df$suitable), ]

# Load occurrence points
occ_data <- read.csv("data/processed/final_model_data.csv")

# Create binary map
p1 <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_tile(data = binary_df, aes(x = x, y = y), fill = "darkgreen", alpha = 0.7) +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "red", size = 2, alpha = 0.8) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "Himalayan Ibex: Suitable Habitat (Binary)",
       subtitle = paste("Total area:", round(total_suitable_area, 0), 
                        "km² (", round(percent_suitable, 1), "% of study area)", sep = ""),
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11))

# Display plot
print(p1)

# Save plot
ggsave("outputs/maps/binary_habitat_map.png", p1, 
       width = 12, height = 10, dpi = 300)
cat("✓ Binary habitat map saved\n\n")

# Regional analysis by country
cat("=== REGIONAL HABITAT ANALYSIS ===\n\n")

# Load country boundaries
countries <- ne_countries(scale = "medium", returnclass = "sf")

# Filter to study area countries
study_countries <- c("Pakistan", "Afghanistan", "India", "China", "Nepal", 
                     "Bhutan", "Tajikistan", "Kyrgyzstan", "Kazakhstan", 
                     "Mongolia", "Uzbekistan")
countries_filtered <- countries[countries$name %in% study_countries, ]

# Convert to terra for analysis
countries_vect <- vect(countries_filtered)
prediction_terra <- rast("outputs/models/habitat_suitability.tif")
binary_terra <- rast("outputs/models/binary_habitat.tif")

# Extract by country
cat("Calculating habitat area by country...\n")

country_stats <- data.frame(
  Country = character(),
  Suitable_Area_km2 = numeric(),
  Percent_of_Country = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(countries_filtered)) {
  country_name <- countries_filtered$name[i]
  
  # Crop to country
  country_mask <- crop(binary_terra, countries_vect[i])
  country_mask <- mask(country_mask, countries_vect[i])
  
  # Calculate area
  suitable_cells_country <- global(country_mask, "sum", na.rm = TRUE)[1, 1]
  
  if (!is.na(suitable_cells_country) && suitable_cells_country > 0) {
    suitable_area_country <- suitable_cells_country * cell_area_km2
    
    # Total country area
    total_cells_country <- global(!is.na(country_mask), "sum", na.rm = TRUE)[1, 1]
    percent_country <- (suitable_cells_country / total_cells_country) * 100
    
    country_stats <- rbind(country_stats, 
                           data.frame(Country = country_name,
                                      Suitable_Area_km2 = round(suitable_area_country, 2),
                                      Percent_of_Country = round(percent_country, 2)))
  }
}

# Sort by area
country_stats <- country_stats[order(-country_stats$Suitable_Area_km2), ]

cat("\nSuitable habitat by country:\n")
print(country_stats)
cat("\n")

# Save country statistics
write.csv(country_stats, "outputs/tables/habitat_by_country.csv", row.names = FALSE)
cat("✓ Country statistics saved\n\n")

# Create country comparison barplot
if (nrow(country_stats) > 0) {
  p2 <- ggplot(country_stats, aes(x = reorder(Country, Suitable_Area_km2), 
                                  y = Suitable_Area_km2)) +
    geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
    coord_flip() +
    labs(title = "Suitable Habitat Area by Country",
         x = "Country", y = "Suitable Area (km²)") +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 14))
  
  # Display plot
  print(p2)
  
  # Save plot
  ggsave("outputs/maps/habitat_by_country.png", p2, 
         width = 10, height = 8, dpi = 300)
  cat("✓ Country comparison plot saved\n\n")
}

# Suitability classes
cat("=== HABITAT SUITABILITY CLASSES ===\n\n")

# Create categorical suitability map
suit_classes <- prediction
values(suit_classes) <- as.numeric(cut(values(prediction), 
                                       breaks = c(0, 0.25, 0.5, 0.75, 1.0),
                                       include.lowest = TRUE))

# Calculate area for each class
low_cells <- cellStats(suit_classes == 1, sum, na.rm = TRUE)
moderate_cells <- cellStats(suit_classes == 2, sum, na.rm = TRUE)
high_cells <- cellStats(suit_classes == 3, sum, na.rm = TRUE)
very_high_cells <- cellStats(suit_classes == 4, sum, na.rm = TRUE)

class_areas <- data.frame(
  Suitability = c("Low", "Moderate", "High", "Very High"),
  Area_km2 = c(
    low_cells * cell_area_km2,
    moderate_cells * cell_area_km2,
    high_cells * cell_area_km2,
    very_high_cells * cell_area_km2
  )
)

class_areas$Percent <- round((class_areas$Area_km2 / sum(class_areas$Area_km2)) * 100, 2)

cat("Habitat suitability classes:\n")
print(class_areas)
cat("\n")

# Save class statistics
write.csv(class_areas, "outputs/tables/suitability_classes.csv", row.names = FALSE)

# Create pie chart
p3 <- ggplot(class_areas, aes(x = "", y = Area_km2, fill = Suitability)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = c("Low" = "#fee5d9", 
                               "Moderate" = "#fcae91",
                               "High" = "#fb6a4a", 
                               "Very High" = "#a50f15")) +
  labs(title = "Distribution of Habitat Suitability Classes",
       fill = "Suitability") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))

# Display plot
print(p3)

# Save plot
ggsave("outputs/maps/suitability_classes_pie.png", p3, 
       width = 8, height = 8, dpi = 300)
cat("✓ Suitability classes plot saved\n\n")

# Summary report
cat("=== SUMMARY REPORT ===\n\n")
cat("Model Performance:\n")
cat("  - Training AUC: 0.977\n")
cat("  - Testing AUC: 0.960\n")
cat("  - Threshold used:", round(threshold_value, 4), "\n\n")

cat("Habitat Area:\n")
cat("  - Total suitable habitat:", round(total_suitable_area, 0), "km²\n")
cat("  - Percentage of study area:", round(percent_suitable, 1), "%\n\n")

cat("Top 3 countries with suitable habitat:\n")
if (nrow(country_stats) > 0) {
  for (i in 1:min(3, nrow(country_stats))) {
    cat("  ", i, ".", country_stats$Country[i], ":", 
        country_stats$Suitable_Area_km2[i], "km²\n")
  }
}

cat("\n=== DAY 8 COMPLETE ===\n")
cat("All analysis files saved in outputs folder\n")
cat("Next: Run Day 9 script for model validation and diagnostics\n")
