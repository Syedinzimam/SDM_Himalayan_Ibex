# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 5 - Variable Selection & Correlation Analysis
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(terra)
library(corrplot)
library(caret)
library(dplyr)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== VARIABLE SELECTION & CORRELATION ANALYSIS ===\n\n")

# Load occurrence data with environmental values
occ_env <- read.csv("data/processed/occurrence_with_environment.csv")
cat("Loaded", nrow(occ_env), "occurrence records with environmental data\n\n")

# Remove ID column and keep only bioclim variables
bioclim_cols <- grep("wc2.1_2.5m_bio", names(occ_env), value = TRUE)
env_data <- occ_env[, bioclim_cols]

cat("Bioclimatic variables:", ncol(env_data), "\n")
cat(paste(names(env_data), collapse = "\n"))
cat("\n\n")

# Rename columns for easier interpretation
colnames(env_data) <- paste0("bio", 1:19)
cat("✓ Renamed variables to bio1-bio19\n\n")

# Check for missing values
cat("Checking for missing values...\n")
na_count <- sum(is.na(env_data))
cat("Total NA values:", na_count, "\n\n")

if (na_count > 0) {
  cat("Removing rows with NA values...\n")
  env_data <- na.omit(env_data)
  cat("Remaining records:", nrow(env_data), "\n\n")
}

# Calculate correlation matrix
cat("=== CORRELATION ANALYSIS ===\n\n")
cat("Calculating correlation matrix...\n")
cor_matrix <- cor(env_data, method = "pearson")

cat("✓ Correlation matrix calculated\n\n")

# Save correlation matrix
write.csv(cor_matrix, "outputs/tables/correlation_matrix.csv")
cat("✓ Correlation matrix saved to: outputs/tables/correlation_matrix.csv\n\n")

# Create correlation plot
cat("Creating correlation visualization...\n")
png("outputs/maps/correlation_plot.png", width = 12, height = 12, 
    units = "in", res = 300)
corrplot(cor_matrix, 
         method = "color",
         type = "upper",
         order = "hclust",
         tl.col = "black",
         tl.srt = 45,
         addCoef.col = "black",
         number.cex = 0.6,
         col = colorRampPalette(c("blue", "white", "red"))(200),
         title = "Bioclimatic Variables Correlation Matrix",
         mar = c(0, 0, 2, 0))
dev.off()

cat("✓ Correlation plot saved to: outputs/maps/correlation_plot.png\n\n")

# Identify highly correlated variables (|r| > 0.7)
cat("=== IDENTIFYING HIGHLY CORRELATED VARIABLES ===\n\n")
high_cor <- findCorrelation(cor_matrix, cutoff = 0.7, names = TRUE)
cat("Highly correlated variables (|r| > 0.7):\n")
cat(paste(high_cor, collapse = ", "), "\n\n")

# Variable selection: Remove highly correlated variables
# Keep biologically meaningful variables for Himalayan Ibex
selected_vars <- c(
  "bio1",   # Annual Mean Temperature
  "bio2",   # Mean Diurnal Range
  "bio3",   # Isothermality
  "bio4",   # Temperature Seasonality
  "bio12",  # Annual Precipitation
  "bio15",  # Precipitation Seasonality
  "bio18",  # Precipitation of Warmest Quarter
  "bio19"   # Precipitation of Coldest Quarter
)

cat("=== SELECTED VARIABLES (8 variables) ===\n\n")
var_descriptions <- c(
  "bio1  - Annual Mean Temperature",
  "bio2  - Mean Diurnal Range",
  "bio3  - Isothermality",
  "bio4  - Temperature Seasonality",
  "bio12 - Annual Precipitation",
  "bio15 - Precipitation Seasonality",
  "bio18 - Precipitation of Warmest Quarter",
  "bio19 - Precipitation of Coldest Quarter"
)
cat(paste(var_descriptions, collapse = "\n"))
cat("\n\n")

# Create reduced dataset
env_selected <- env_data[, selected_vars]

# Check correlation of selected variables
cat("Correlation of selected variables:\n\n")
cor_selected <- cor(env_selected)
print(round(cor_selected, 2))
cat("\n")

# Save selected correlation matrix
write.csv(cor_selected, "outputs/tables/correlation_selected.csv")
cat("✓ Selected variables correlation saved\n\n")

# Create correlation plot for selected variables
png("outputs/maps/correlation_selected.png", width = 10, height = 10, 
    units = "in", res = 300)
corrplot(cor_selected, 
         method = "color",
         type = "upper",
         tl.col = "black",
         tl.srt = 45,
         addCoef.col = "black",
         number.cex = 0.8,
         col = colorRampPalette(c("blue", "white", "red"))(200),
         title = "Selected Variables Correlation Matrix",
         mar = c(0, 0, 2, 0))
dev.off()

cat("✓ Selected variables plot saved\n\n")

# Prepare final dataset for modeling
cat("=== PREPARING FINAL DATASET ===\n\n")

# Get occurrence coordinates
coords <- occ_env[, c("longitude", "latitude")]

# Combine coordinates with selected environmental variables
final_data <- cbind(coords, env_selected)

# Add species column
final_data$species <- "Capra sibirica"

# Reorder columns
final_data <- final_data[, c("species", "longitude", "latitude", selected_vars)]

cat("Final dataset structure:\n")
str(final_data)
cat("\n")

# Save final dataset
write.csv(final_data, "data/processed/final_model_data.csv", row.names = FALSE)
cat("✓ Final dataset saved to: data/processed/final_model_data.csv\n\n")

# Summary statistics for selected variables
cat("=== SUMMARY STATISTICS FOR SELECTED VARIABLES ===\n\n")
summary_selected <- data.frame(
  Variable = selected_vars,
  Mean = round(colMeans(env_selected), 2),
  SD = round(apply(env_selected, 2, sd), 2),
  Min = round(apply(env_selected, 2, min), 2),
  Max = round(apply(env_selected, 2, max), 2)
)

print(summary_selected)

# Save summary
write.csv(summary_selected, "outputs/tables/selected_variables_summary.csv", 
          row.names = FALSE)
cat("\n✓ Summary saved to: outputs/tables/selected_variables_summary.csv\n")

# Load and prepare environmental rasters for modeling
cat("\n=== PREPARING ENVIRONMENTAL LAYERS FOR MODELING ===\n\n")

# Load cropped bioclim data
bioclim_cropped <- rast("data/environmental/bioclim_cropped.tif")

# Rename layers
names(bioclim_cropped) <- paste0("bio", 1:19)

# Select only the chosen variables
bioclim_selected <- bioclim_cropped[[selected_vars]]

# Save selected environmental layers
writeRaster(bioclim_selected, 
            "data/environmental/bioclim_selected.tif",
            overwrite = TRUE)

cat("✓ Selected environmental layers saved\n")
cat("  Layers:", nlyr(bioclim_selected), "\n")
cat("  Variables:", paste(names(bioclim_selected), collapse = ", "), "\n\n")

cat("=== DAY 5 COMPLETE ===\n")
cat("Summary:\n")
cat("  - Started with 19 bioclimatic variables\n")
cat("  - Reduced to 8 uncorrelated variables\n")
cat("  - Final dataset:", nrow(final_data), "occurrence points\n")
cat("  - Ready for MaxEnt modeling\n\n")
cat("Next: Run Day 6 script for background point generation\n")
