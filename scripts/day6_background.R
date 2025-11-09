# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 6 - Background Point Generation
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(terra)
library(dismo)
library(sf)
library(ggplot2)
library(rnaturalearth)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== BACKGROUND POINT GENERATION FOR MAXENT ===\n\n")

# Load occurrence data
occ_data <- read.csv("data/processed/final_model_data.csv")
cat("Loaded", nrow(occ_data), "occurrence points\n\n")

# Load environmental layers
env_layers <- rast("data/environmental/bioclim_selected.tif")
cat("Loaded", nlyr(env_layers), "environmental layers:\n")
cat(paste(names(env_layers), collapse = ", "), "\n\n")

# Generate background points
# Rule of thumb: 10,000 points or 10x more than presence points
n_background <- 10000

cat("Generating", n_background, "background points...\n")
cat("This ensures good coverage of available environment\n\n")

# Generate random points across study area (using first layer as mask)
set.seed(123)  # For reproducibility
background_points <- spatSample(env_layers[[1]], 
                                size = n_background, 
                                method = "random",
                                na.rm = TRUE,
                                xy = TRUE,
                                values = FALSE)

# Convert to data frame
bg_coords <- as.data.frame(background_points)
colnames(bg_coords) <- c("longitude", "latitude")

cat("✓ Generated", nrow(bg_coords), "background points\n\n")

# Remove background points too close to presence points (buffer = 10km ~ 0.1 degrees)
cat("Removing background points near occurrences (10km buffer)...\n")

# Calculate distances
distances <- pointDistance(
  bg_coords[, c("longitude", "latitude")],
  occ_data[, c("longitude", "latitude")],
  lonlat = TRUE
)

# Keep background points > 10km from any presence
min_distances <- apply(distances, 1, min)
bg_filtered <- bg_coords[min_distances > 10000, ]

cat("✓ Filtered to", nrow(bg_filtered), "background points\n\n")

# Extract environmental values for background points
cat("Extracting environmental values for background points...\n")
bg_env <- extract(env_layers, bg_filtered[, c("longitude", "latitude")])

# Combine coordinates with environmental values
bg_final <- cbind(bg_filtered, bg_env)

# Remove any rows with NA
bg_final <- na.omit(bg_final)

cat("✓ Final background points:", nrow(bg_final), "\n\n")

# Save background data
write.csv(bg_final, "data/processed/background_points.csv", row.names = FALSE)
cat("✓ Background data saved to: data/processed/background_points.csv\n\n")

# Create visualization
cat("=== CREATING VISUALIZATIONS ===\n\n")

# Get world map
world <- ne_countries(scale = "medium", returnclass = "sf")

# Define study extent
study_extent <- c(60, 25, 105, 45)

# Create presence vs background map
p1 <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_point(data = bg_final, aes(x = longitude, y = latitude), 
             color = "gray70", size = 0.5, alpha = 0.3) +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "red", size = 2, alpha = 0.8) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "Himalayan Ibex: Presence vs Background Points",
       subtitle = paste("Red = Presence (n=", nrow(occ_data), 
                        "), Gray = Background (n=", nrow(bg_final), ")", sep = ""),
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

# Display in R console
print(p1)

# Save plot
ggsave("outputs/maps/presence_background_map.png", p1, 
       width = 10, height = 8, dpi = 300)
cat("✓ Map saved to: outputs/maps/presence_background_map.png\n\n")

# Environmental space comparison
cat("Comparing environmental space...\n\n")

# Combine presence and background data
occ_data$type <- "Presence"
bg_sample <- bg_final[sample(nrow(bg_final), nrow(occ_data) * 2), ]
bg_sample$type <- "Background"

combined_data <- rbind(
  occ_data[, c("bio1", "bio12", "type")],
  bg_sample[, c("bio1", "bio12", "type")]
)

# Create environmental space plot
p2 <- ggplot(combined_data, aes(x = bio1, y = bio12, color = type)) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c("Background" = "gray", "Presence" = "red")) +
  labs(title = "Environmental Space: Temperature vs Precipitation",
       x = "Annual Mean Temperature (°C)",
       y = "Annual Precipitation (mm)",
       color = "Point Type") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12),
        legend.position = "bottom")

# Display in R console
print(p2)

# Save plot
ggsave("outputs/maps/environmental_space.png", p2, 
       width = 8, height = 6, dpi = 300)
cat("✓ Environmental space plot saved\n\n")

# Summary statistics comparison
cat("=== ENVIRONMENTAL COMPARISON: PRESENCE VS BACKGROUND ===\n\n")

# Temperature comparison
cat("Annual Mean Temperature (bio1):\n")
cat("  Presence  - Mean:", round(mean(occ_data$bio1), 2), 
    "°C, SD:", round(sd(occ_data$bio1), 2), "\n")
cat("  Background - Mean:", round(mean(bg_final$bio1), 2), 
    "°C, SD:", round(sd(bg_final$bio1), 2), "\n\n")

# Precipitation comparison
cat("Annual Precipitation (bio12):\n")
cat("  Presence  - Mean:", round(mean(occ_data$bio12), 2), 
    "mm, SD:", round(sd(occ_data$bio12), 2), "\n")
cat("  Background - Mean:", round(mean(bg_final$bio12), 2), 
    "mm, SD:", round(sd(bg_final$bio12), 2), "\n\n")

# Create comparison boxplots for key variables
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

# bio1
boxplot(list(Presence = occ_data$bio1, Background = bg_final$bio1),
        main = "Annual Mean Temperature",
        ylab = "Temperature (°C)",
        col = c("red", "gray"))

# bio12
boxplot(list(Presence = occ_data$bio12, Background = bg_final$bio12),
        main = "Annual Precipitation",
        ylab = "Precipitation (mm)",
        col = c("red", "gray"))

# bio4
boxplot(list(Presence = occ_data$bio4, Background = bg_final$bio4),
        main = "Temperature Seasonality",
        ylab = "Standard Deviation",
        col = c("red", "gray"))

# bio15
boxplot(list(Presence = occ_data$bio15, Background = bg_final$bio15),
        main = "Precipitation Seasonality",
        ylab = "Coefficient of Variation",
        col = c("red", "gray"))

# Save boxplot
dev.copy(png, "outputs/maps/environmental_comparison_boxplots.png", 
         width = 10, height = 8, units = "in", res = 300)
dev.off()

cat("✓ Boxplots saved to: outputs/maps/environmental_comparison_boxplots.png\n\n")

cat("=== DAY 6 COMPLETE ===\n")
cat("Summary:\n")
cat("  - Presence points:", nrow(occ_data), "\n")
cat("  - Background points:", nrow(bg_final), "\n")
cat("  - Environmental layers: 8 variables\n")
cat("  - Data ready for MaxEnt modeling\n\n")
cat("Next: Run Day 7 script to build MaxEnt model\n")
