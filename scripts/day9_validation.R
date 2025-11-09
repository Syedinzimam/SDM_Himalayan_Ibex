# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 9 - Model Validation & Diagnostics
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(raster)
library(dismo)
library(ggplot2)
library(gridExtra)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== MODEL VALIDATION & DIAGNOSTICS ===\n\n")

# Load data
maxent_model <- readRDS("outputs/models/maxent_model.rds")
env_stack <- raster::stack("data/environmental/bioclim_selected.tif")
names(env_stack) <- paste0("bio", c(1, 2, 3, 4, 12, 15, 18, 19))
presence <- read.csv("data/processed/final_model_data.csv")
background <- read.csv("data/processed/background_points.csv")

presence_coords <- presence[, c("longitude", "latitude")]
background_coords <- background[, c("longitude", "latitude")]

cat("✓ Data loaded\n\n")

# ============================================================================
# 1. VARIABLE IMPORTANCE ANALYSIS
# ============================================================================
cat("=== VARIABLE IMPORTANCE ANALYSIS ===\n\n")

# Extract permutation importance
perm_importance <- maxent_model@results[grep("permutation.importance", 
                                             rownames(maxent_model@results)), ]
perm_importance <- sort(perm_importance, decreasing = TRUE)

cat("Permutation Importance (%):\n")
print(round(perm_importance, 2))
cat("\n")

# Extract percent contribution
contribution <- maxent_model@results[grep("contribution", 
                                          rownames(maxent_model@results)), ]
contribution <- sort(contribution, decreasing = TRUE)

cat("Percent Contribution (%):\n")
print(round(contribution, 2))
cat("\n")

# Create variable importance plot
var_names <- gsub(".permutation.importance", "", names(perm_importance))
var_names <- gsub(".contribution", "", names(contribution))

importance_df <- data.frame(
  Variable = names(contribution),
  Contribution = as.numeric(contribution),
  Permutation = as.numeric(perm_importance[names(contribution)])
)
importance_df$Variable <- gsub(".contribution", "", importance_df$Variable)

# Plot
p1 <- ggplot(importance_df, aes(x = reorder(Variable, Contribution))) +
  geom_bar(aes(y = Contribution, fill = "Contribution"), 
           stat = "identity", position = "dodge", alpha = 0.7) +
  geom_point(aes(y = Permutation, color = "Permutation"), size = 4) +
  coord_flip() +
  labs(title = "Variable Importance",
       x = "Variable", y = "Importance (%)") +
  scale_fill_manual(values = c("Contribution" = "steelblue")) +
  scale_color_manual(values = c("Permutation" = "red")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.title = element_blank())

print(p1)
ggsave("outputs/maps/variable_importance.png", p1, width = 10, height = 6, dpi = 300)
cat("✓ Variable importance plot saved\n\n")

# ============================================================================
# 2. RESPONSE CURVES DETAILED ANALYSIS
# ============================================================================
cat("=== RESPONSE CURVES ANALYSIS ===\n\n")

# Create detailed response curves for top 4 variables
top_vars <- names(contribution)[1:4]
cat("Analyzing response curves for top variables:\n")
cat(paste(top_vars, collapse = ", "), "\n\n")

# Generate response data
response_plots <- list()

for (i in 1:length(top_vars)) {
  var <- gsub(".contribution", "", top_vars[i])
  
  # Get variable range
  var_values <- values(env_stack[[var]])
  var_range <- seq(min(var_values, na.rm = TRUE), 
                   max(var_values, na.rm = TRUE), 
                   length.out = 100)
  
  # Create data frame for prediction
  test_data <- as.data.frame(matrix(
    rep(colMeans(values(env_stack), na.rm = TRUE), each = 100),
    nrow = 100
  ))
  colnames(test_data) <- names(env_stack)
  test_data[[var]] <- var_range
  
  # Predict
  response_pred <- predict(maxent_model, test_data, args = "outputformat=logistic")
  
  # Create plot
  response_df <- data.frame(
    Variable_Value = var_range,
    Suitability = response_pred
  )
  
  p <- ggplot(response_df, aes(x = Variable_Value, y = Suitability)) +
    geom_line(color = "steelblue", linewidth = 1.2) +
    geom_rug(data = data.frame(var_val = presence[[var]]), 
             aes(x = var_val, y = NULL), inherit.aes = FALSE,
             sides = "b", color = "red", alpha = 0.5) +
    labs(title = paste("Response Curve:", var),
         x = var, y = "Habitat Suitability") +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 12))
  
  response_plots[[i]] <- p
}

# Arrange and display
combined_response <- grid.arrange(grobs = response_plots, ncol = 2)

# Save
ggsave("outputs/maps/response_curves_detailed.png", combined_response, 
       width = 12, height = 10, dpi = 300)
cat("✓ Detailed response curves saved\n\n")

# ============================================================================
# 3. MODEL PREDICTIONS AT PRESENCE LOCATIONS
# ============================================================================
cat("=== PREDICTION ANALYSIS AT PRESENCE LOCATIONS ===\n\n")

# Extract predictions at presence points
presence_predictions <- extract(raster("outputs/models/habitat_suitability.tif"), 
                                presence_coords)

cat("Predictions at presence locations:\n")
cat("  Mean:", round(mean(presence_predictions, na.rm = TRUE), 3), "\n")
cat("  Median:", round(median(presence_predictions, na.rm = TRUE), 3), "\n")
cat("  Min:", round(min(presence_predictions, na.rm = TRUE), 3), "\n")
cat("  Max:", round(max(presence_predictions, na.rm = TRUE), 3), "\n\n")

# Create histogram
pred_df <- data.frame(Prediction = presence_predictions)

p2 <- ggplot(pred_df, aes(x = Prediction)) +
  geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7, color = "black") +
  geom_vline(xintercept = mean(presence_predictions, na.rm = TRUE), 
             color = "red", linetype = "dashed", size = 1) +
  labs(title = "Distribution of Predictions at Presence Locations",
       subtitle = paste("Mean =", round(mean(presence_predictions, na.rm = TRUE), 3)),
       x = "Predicted Suitability", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

print(p2)
ggsave("outputs/maps/presence_predictions_histogram.png", p2, 
       width = 10, height = 6, dpi = 300)
cat("✓ Prediction histogram saved\n\n")

# ============================================================================
# 4. SPATIAL VALIDATION (K-FOLD CROSS-VALIDATION)
# ============================================================================
cat("=== SPATIAL CROSS-VALIDATION ===\n\n")
cat("Performing 5-fold spatial cross-validation...\n")
cat("This may take several minutes...\n\n")

set.seed(123)
k <- 5
folds <- kfold(presence_coords, k = k)

cv_results <- data.frame(
  Fold = integer(),
  AUC = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:k) {
  cat("  Processing fold", i, "of", k, "...\n")
  
  # Split data
  train_pres <- presence_coords[folds != i, ]
  test_pres <- presence_coords[folds == i, ]
  
  # Sample background
  bg_sample <- background_coords[sample(nrow(background_coords), 
                                        nrow(train_pres) * 20), ]
  
  # Train model
  fold_model <- maxent(env_stack, train_pres, bg_sample, 
                       args = c("noaddsamplestobackground"))
  
  # Evaluate
  fold_eval <- evaluate(test_pres, bg_sample, fold_model, env_stack)
  
  cv_results <- rbind(cv_results, 
                      data.frame(Fold = i, AUC = fold_eval@auc))
}

cat("\n✓ Cross-validation complete\n\n")
cat("Cross-validation results:\n")
print(cv_results)
cat("\n")
cat("Mean AUC:", round(mean(cv_results$AUC), 3), "\n")
cat("SD AUC:", round(sd(cv_results$AUC), 3), "\n\n")

# Save CV results
write.csv(cv_results, "outputs/tables/cross_validation_results.csv", 
          row.names = FALSE)

# Plot CV results
p3 <- ggplot(cv_results, aes(x = factor(Fold), y = AUC)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_hline(yintercept = mean(cv_results$AUC), 
             color = "red", linetype = "dashed", size = 1) +
  ylim(0, 1) +
  labs(title = "5-Fold Cross-Validation Results",
       subtitle = paste("Mean AUC =", round(mean(cv_results$AUC), 3)),
       x = "Fold", y = "AUC") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

print(p3)
ggsave("outputs/maps/cross_validation_auc.png", p3, 
       width = 10, height = 6, dpi = 300)
cat("✓ Cross-validation plot saved\n\n")

# ============================================================================
# 5. MODEL DIAGNOSTIC SUMMARY
# ============================================================================
cat("=== MODEL DIAGNOSTIC SUMMARY ===\n\n")

# Load evaluation results
eval_results <- read.csv("outputs/tables/model_evaluation.csv")

cat("Model Performance Summary:\n")
cat("─────────────────────────────\n")
cat("Training AUC:", round(eval_results$AUC[1], 3), "\n")
cat("Testing AUC:", round(eval_results$AUC[2], 3), "\n")
cat("Cross-validation AUC:", round(mean(cv_results$AUC), 3), 
    "±", round(sd(cv_results$AUC), 3), "\n\n")

cat("Model Interpretation:\n")
cat("─────────────────────────────\n")
if (mean(cv_results$AUC) >= 0.9) {
  cat("✓ EXCELLENT model performance (AUC ≥ 0.9)\n")
} else if (mean(cv_results$AUC) >= 0.8) {
  cat("✓ GOOD model performance (0.8 ≤ AUC < 0.9)\n")
} else if (mean(cv_results$AUC) >= 0.7) {
  cat("⚠ FAIR model performance (0.7 ≤ AUC < 0.8)\n")
} else {
  cat("✗ POOR model performance (AUC < 0.7)\n")
}
cat("\n")

cat("Top 3 Important Variables:\n")
cat("─────────────────────────────\n")
for (i in 1:3) {
  var_name <- gsub(".contribution", "", names(contribution)[i])
  cat(i, ".", var_name, ":", round(contribution[i], 1), "%\n")
}
cat("\n")

cat("Presence Point Statistics:\n")
cat("─────────────────────────────\n")
cat("Mean prediction at presence:", 
    round(mean(presence_predictions, na.rm = TRUE), 3), "\n")
cat("Total presence points:", nrow(presence), "\n\n")

# Create summary table
summary_table <- data.frame(
  Metric = c("Training AUC", "Testing AUC", "CV AUC Mean", "CV AUC SD",
             "Top Variable", "Mean Presence Prediction"),
  Value = c(
    round(eval_results$AUC[1], 3),
    round(eval_results$AUC[2], 3),
    round(mean(cv_results$AUC), 3),
    round(sd(cv_results$AUC), 3),
    gsub(".contribution", "", names(contribution)[1]),
    round(mean(presence_predictions, na.rm = TRUE), 3)
  )
)

write.csv(summary_table, "outputs/tables/model_diagnostic_summary.csv", 
          row.names = FALSE)

cat("=== DAY 9 COMPLETE ===\n")
cat("Summary:\n")
cat("  - Variable importance analyzed\n")
cat("  - Response curves generated\n")
cat("  - Spatial cross-validation completed\n")
cat("  - Model diagnostics saved\n")
cat("  - Mean CV AUC:", round(mean(cv_results$AUC), 3), "\n\n")
cat("Next: Run Day 10 script for final visualizations and reporting\n")
