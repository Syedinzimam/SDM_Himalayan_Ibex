# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 7 - MaxEnt Model Building
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(dismo)
library(rJava)
library(terra)
library(raster)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== MAXENT MODEL BUILDING ===\n\n")

# Check if MaxEnt is available
cat("Checking MaxEnt availability...\n")
maxent_jar <- file.path(system.file("java", package = "dismo"), "maxent.jar")

if (!file.exists(maxent_jar)) {
  stop("MaxEnt not found! Please download maxent.jar from:\n",
       "https://biodiversityinformatics.amnh.org/open_source/maxent/\n",
       "and place it in: ", system.file("java", package = "dismo"))
}

cat("✓ MaxEnt is available\n\n")

# Load data
cat("Loading data...\n")
presence <- read.csv("data/processed/final_model_data.csv")
background <- read.csv("data/processed/background_points.csv")

cat("  Presence points:", nrow(presence), "\n")
cat("  Background points:", nrow(background), "\n\n")

# Load environmental layers
env_layers <- rast("data/environmental/bioclim_selected.tif")

# Convert SpatRaster to RasterStack for dismo compatibility
env_stack <- raster::stack("data/environmental/bioclim_selected.tif")
names(env_stack) <- names(env_layers)

cat("  Environmental layers:", nlayers(env_stack), "\n")
cat("  Variables:", paste(names(env_stack), collapse = ", "), "\n\n")

# Prepare coordinates
presence_coords <- presence[, c("longitude", "latitude")]
background_coords <- background[, c("longitude", "latitude")]

# Split data into training (80%) and testing (20%)
cat("=== DATA SPLITTING ===\n\n")
set.seed(123)

# Training/testing split for presence
train_indices <- sample(1:nrow(presence_coords), 
                        size = floor(0.8 * nrow(presence_coords)))
presence_train <- presence_coords[train_indices, ]
presence_test <- presence_coords[-train_indices, ]

# Sample background for training (same ratio)
bg_train_size <- floor(0.8 * nrow(background_coords))
bg_train_indices <- sample(1:nrow(background_coords), size = bg_train_size)
background_train <- background_coords[bg_train_indices, ]
background_test <- background_coords[-bg_train_indices, ]

cat("Training data:\n")
cat("  Presence:", nrow(presence_train), "\n")
cat("  Background:", nrow(background_train), "\n")
cat("\nTesting data:\n")
cat("  Presence:", nrow(presence_test), "\n")
cat("  Background:", nrow(background_test), "\n\n")

# Build MaxEnt model
cat("=== BUILDING MAXENT MODEL ===\n")
cat("This may take several minutes...\n\n")

# Create output directory for MaxEnt
dir.create("outputs/models/maxent_output", recursive = TRUE, showWarnings = FALSE)

# Run MaxEnt
maxent_model <- maxent(
  x = env_stack,
  p = presence_train,
  a = background_train,
  path = "outputs/models/maxent_output",
  args = c(
    "responsecurves=true",
    "jackknife=true",
    "plots=true",
    "writeplotdata=true"
  )
)

cat("✓ MaxEnt model built successfully!\n\n")

# Save model object
saveRDS(maxent_model, "outputs/models/maxent_model.rds")
cat("✓ Model saved to: outputs/models/maxent_model.rds\n\n")

# Model evaluation
cat("=== MODEL EVALUATION ===\n\n")

# Predict on training data
cat("Evaluating training data...\n")
eval_train <- evaluate(
  p = presence_train,
  a = background_train,
  model = maxent_model,
  x = env_stack
)

# Predict on testing data
cat("Evaluating testing data...\n")
eval_test <- evaluate(
  p = presence_test,
  a = background_test,
  model = maxent_model,
  x = env_stack
)

cat("\n=== TRAINING PERFORMANCE ===\n")
cat("AUC:", round(eval_train@auc, 3), "\n")
cat("Correlation:", round(eval_train@cor, 3), "\n\n")

cat("=== TESTING PERFORMANCE ===\n")
cat("AUC:", round(eval_test@auc, 3), "\n")
cat("Correlation:", round(eval_test@cor, 3), "\n\n")

# Interpretation of AUC
if (eval_test@auc >= 0.9) {
  cat("Model performance: EXCELLENT\n")
} else if (eval_test@auc >= 0.8) {
  cat("Model performance: GOOD\n")
} else if (eval_test@auc >= 0.7) {
  cat("Model performance: FAIR\n")
} else {
  cat("Model performance: POOR\n")
}
cat("\n")

# Variable importance
cat("=== VARIABLE IMPORTANCE ===\n\n")
var_importance <- maxent_model@results[grep("contribution", 
                                            rownames(maxent_model@results)), ]
var_importance <- sort(var_importance, decreasing = TRUE)
print(round(var_importance, 2))
cat("\n")

# Save evaluation results
eval_results <- data.frame(
  Dataset = c("Training", "Testing"),
  AUC = c(eval_train@auc, eval_test@auc),
  Correlation = c(eval_train@cor, eval_test@cor)
)
write.csv(eval_results, "outputs/tables/model_evaluation.csv", row.names = FALSE)
cat("✓ Evaluation results saved\n\n")

# Response curves plot
cat("Creating response curves...\n")
png("outputs/maps/response_curves.png", width = 12, height = 10, 
    units = "in", res = 300)
response(maxent_model)
dev.off()
cat("✓ Response curves saved and displayed\n\n")

# ROC curves
cat("Creating ROC curves...\n")
png("outputs/maps/roc_curves.png", width = 10, height = 5, 
    units = "in", res = 300)
par(mfrow = c(1, 2))

# Training ROC
plot(eval_train, 'ROC', main = "Training Data ROC")
text(0.6, 0.2, paste("AUC =", round(eval_train@auc, 3)), cex = 1.2)

# Testing ROC
plot(eval_test, 'ROC', main = "Testing Data ROC")
text(0.6, 0.2, paste("AUC =", round(eval_test@auc, 3)), cex = 1.2)

dev.off()
cat("✓ ROC curves saved and displayed\n\n")

# Threshold selection
cat("=== THRESHOLD SELECTION ===\n\n")
thresholds <- threshold(eval_test)
cat("Recommended thresholds:\n")
print(thresholds)
cat("\n")

# Save thresholds
write.csv(thresholds, "outputs/tables/model_thresholds.csv")
cat("✓ Thresholds saved\n\n")

# Generate predictions
cat("=== GENERATING PREDICTIONS ===\n\n")
cat("Predicting habitat suitability across study area...\n")

prediction <- predict(maxent_model, env_stack)

# Save prediction raster
writeRaster(raster(prediction), 
            "outputs/models/habitat_suitability.tif",
            overwrite = TRUE)

cat("✓ Prediction raster saved\n\n")

# Create prediction map
cat("Creating prediction map...\n")
png("outputs/maps/habitat_suitability_map.png", width = 12, height = 10, 
    units = "in", res = 300)

plot(prediction, 
     main = "Himalayan Ibex Habitat Suitability",
     col = rev(terrain.colors(100)),
     axes = FALSE,
     box = FALSE)

# Add presence points
points(presence_coords, pch = 20, cex = 0.8, col = "red")

# Add legend
legend("topright", 
       legend = c("Presence", "Low Suitability", "High Suitability"),
       pch = c(20, 15, 15),
       col = c("red", terrain.colors(100)[1], terrain.colors(100)[100]),
       bg = "white")

dev.off()
cat("✓ Habitat suitability map saved and displayed\n\n")

cat("=== DAY 7 COMPLETE ===\n")
cat("Summary:\n")
cat("  - MaxEnt model successfully built\n")
cat("  - Training AUC:", round(eval_train@auc, 3), "\n")
cat("  - Testing AUC:", round(eval_test@auc, 3), "\n")
cat("  - Habitat suitability map created\n")
cat("  - All results saved in outputs folder\n\n")
cat("Next: Run Day 8 script for advanced model analysis\n")

