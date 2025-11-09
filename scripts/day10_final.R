# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 10 - Final Report & Publication Figures
# DATE: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
library(raster)
library(terra)
library(sf)
library(ggplot2)
library(gridExtra)
library(rnaturalearth)
library(dplyr)

# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

cat("=== FINAL REPORT & PUBLICATION-QUALITY FIGURES ===\n\n")

# ============================================================================
# 1. CREATE COMPOSITE FIGURE - WORKFLOW
# ============================================================================
cat("Creating workflow composite figure...\n")

# Load data
world <- ne_countries(scale = "medium", returnclass = "sf")
study_extent <- c(60, 25, 105, 45)
occ_data <- read.csv("data/processed/final_model_data.csv")
prediction <- raster("outputs/models/habitat_suitability.tif")
binary_habitat <- raster("outputs/models/binary_habitat.tif")

# Panel A: Occurrence points
p_occ <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "red", size = 2.5, alpha = 0.8) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "(A) Occurrence Data",
       subtitle = paste("n =", nrow(occ_data), "records")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12),
        axis.title = element_blank())

# Panel B: Habitat Suitability
pred_df <- as.data.frame(prediction, xy = TRUE)
colnames(pred_df) <- c("x", "y", "suitability")

p_suit <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_raster(data = pred_df, aes(x = x, y = y, fill = suitability)) +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "black", size = 1, alpha = 0.6) +
  scale_fill_viridis_c(option = "plasma", name = "Suitability") +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "(B) Habitat Suitability") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12),
        axis.title = element_blank(),
        legend.position = "bottom")

# Panel C: Binary Classification
binary_df <- as.data.frame(binary_habitat, xy = TRUE)
colnames(binary_df) <- c("x", "y", "suitable")
binary_df <- binary_df[!is.na(binary_df$suitable), ]

p_binary <- ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") +
  geom_tile(data = binary_df, aes(x = x, y = y), 
            fill = "darkgreen", alpha = 0.7) +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "red", size = 1.5, alpha = 0.8) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "(C) Suitable Habitat") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12),
        axis.title = element_blank())

# Panel D: Variable Importance
maxent_model <- readRDS("outputs/models/maxent_model.rds")
contribution <- maxent_model@results[grep("contribution", 
                                          rownames(maxent_model@results)), ]
contribution <- sort(contribution, decreasing = TRUE)

importance_df <- data.frame(
  Variable = gsub(".contribution", "", names(contribution)),
  Contribution = as.numeric(contribution)
)

p_var <- ggplot(importance_df, aes(x = reorder(Variable, Contribution), 
                                   y = Contribution)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "(D) Variable Importance",
       x = NULL, y = "Contribution (%)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12))

# Combine panels
composite <- grid.arrange(p_occ, p_suit, p_binary, p_var, 
                          ncol = 2, nrow = 2)

# Save high-resolution composite
ggsave("outputs/maps/Figure1_Workflow_Composite.png", composite, 
       width = 14, height = 12, dpi = 600)

cat("✓ Workflow composite saved\n\n")

# ============================================================================
# 2. CREATE MODEL PERFORMANCE FIGURE
# ============================================================================
cat("Creating model performance figure...\n")

# Load evaluation data
eval_results <- read.csv("outputs/tables/model_evaluation.csv")
cv_results <- read.csv("outputs/tables/cross_validation_results.csv")

# Panel A: AUC Comparison
auc_df <- data.frame(
  Dataset = c("Training", "Testing", rep("CV", 5)),
  AUC = c(eval_results$AUC, cv_results$AUC),
  Type = c("Training", "Testing", rep("Cross-Validation", 5))
)

p_auc <- ggplot(auc_df, aes(x = Dataset, y = AUC, fill = Type)) +
  geom_bar(stat = "identity", alpha = 0.7) +
  geom_hline(yintercept = 0.9, linetype = "dashed", color = "red") +
  ylim(0, 1) +
  scale_fill_manual(values = c("Training" = "#2E86AB", 
                               "Testing" = "#A23B72",
                               "Cross-Validation" = "#F18F01")) +
  labs(title = "(A) Model Performance Across Datasets",
       x = NULL, y = "AUC") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12),
        legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))

# Panel B: Prediction Distribution
presence_predictions <- extract(prediction, occ_data[, c("longitude", "latitude")])
pred_df_hist <- data.frame(Prediction = presence_predictions)

p_pred <- ggplot(pred_df_hist, aes(x = Prediction)) +
  geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7, color = "black") +
  geom_vline(xintercept = mean(presence_predictions, na.rm = TRUE), 
             color = "red", linetype = "dashed", linewidth = 1) +
  labs(title = "(B) Predictions at Presence Locations",
       x = "Predicted Suitability", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12))

# Combine
performance_fig <- grid.arrange(p_auc, p_pred, ncol = 2)

ggsave("outputs/maps/Figure2_Model_Performance.png", performance_fig, 
       width = 12, height = 5, dpi = 600)

cat("✓ Model performance figure saved\n\n")

# ============================================================================
# 3. CREATE FINAL HABITAT SUITABILITY MAP (PUBLICATION QUALITY)
# ============================================================================
cat("Creating publication-quality habitat map...\n")

# High-resolution map with country boundaries
countries <- ne_countries(scale = "medium", returnclass = "sf")

final_map <- ggplot() +
  geom_raster(data = pred_df, aes(x = x, y = y, fill = suitability)) +
  geom_sf(data = countries, fill = NA, color = "gray30", linewidth = 0.3) +
  geom_point(data = occ_data, aes(x = longitude, y = latitude), 
             color = "white", size = 2, shape = 21, fill = "red", stroke = 0.5) +
  scale_fill_viridis_c(option = "plasma", 
                       name = "Habitat\nSuitability",
                       breaks = seq(0, 1, 0.2)) +
  coord_sf(xlim = c(study_extent[1], study_extent[3]), 
           ylim = c(study_extent[2], study_extent[4])) +
  labs(title = "Himalayan Ibex (Capra sibirica) Habitat Suitability Model",
       subtitle = "MaxEnt Species Distribution Model | AUC = 0.96",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    legend.position = "right",
    panel.grid = element_line(color = "gray90"),
    panel.background = element_rect(fill = "aliceblue")
  )

print(final_map)

ggsave("outputs/maps/Figure3_Final_Habitat_Map.png", final_map, 
       width = 16, height = 10, dpi = 600)

cat("✓ Publication-quality habitat map saved\n\n")

# ============================================================================
# 4. GENERATE COMPREHENSIVE PROJECT SUMMARY
# ============================================================================
cat("=== GENERATING PROJECT SUMMARY ===\n\n")

summary_text <- paste0(
  "================================================================================\n",
  "SPECIES DISTRIBUTION MODELING PROJECT SUMMARY\n",
  "Himalayan Ibex (Capra sibirica)\n",
  "================================================================================\n\n",
  
  "PROJECT INFORMATION\n",
  "-------------------\n",
  "Author: Syed Inzimam Ali Shah\n",
  "GitHub: https://github.com/Syedinzimam\n",
  "Duration: 15 days (", Sys.Date() - 9, " to ", Sys.Date(), ")\n",
  "Species: Capra sibirica (Himalayan Ibex)\n",
  "Study Area: Southeast Asia (60°E-105°E, 25°N-45°N)\n\n",
  
  "DATA SUMMARY\n",
  "------------\n",
  "Occurrence Records: ", nrow(occ_data), " points (GBIF)\n",
  "Date Range: 1883-2025\n",
  "Background Points: 9,994 points\n",
  "Environmental Variables: 8 bioclimatic variables (WorldClim)\n",
  "  - bio1: Annual Mean Temperature\n",
  "  - bio2: Mean Diurnal Range\n",
  "  - bio3: Isothermality\n",
  "  - bio4: Temperature Seasonality\n",
  "  - bio12: Annual Precipitation\n",
  "  - bio15: Precipitation Seasonality\n",
  "  - bio18: Precipitation of Warmest Quarter\n",
  "  - bio19: Precipitation of Coldest Quarter\n\n",
  
  "MODEL PERFORMANCE\n",
  "-----------------\n",
  "Algorithm: MaxEnt (Maximum Entropy)\n",
  "Training AUC: ", round(eval_results$AUC[1], 3), "\n",
  "Testing AUC: ", round(eval_results$AUC[2], 3), "\n",
  "Cross-Validation AUC: ", round(mean(cv_results$AUC), 3), " ± ", 
  round(sd(cv_results$AUC), 3), "\n",
  "Performance Rating: EXCELLENT (AUC > 0.9)\n\n",
  
  "VARIABLE IMPORTANCE\n",
  "-------------------\n",
  "Top 3 Contributing Variables:\n",
  "1. ", importance_df$Variable[1], ": ", round(importance_df$Contribution[1], 1), "%\n",
  "2. ", importance_df$Variable[2], ": ", round(importance_df$Contribution[2], 1), "%\n",
  "3. ", importance_df$Variable[3], ": ", round(importance_df$Contribution[3], 1), "%\n\n",
  
  "HABITAT ANALYSIS\n",
  "----------------\n",
  "Total Suitable Habitat: 1,607,905 km²\n",
  "Percentage of Study Area: 17.7%\n",
  "Mean Prediction at Presence: ", round(mean(presence_predictions, na.rm = TRUE), 3), "\n\n",
  
  "TOP COUNTRIES WITH SUITABLE HABITAT\n",
  "-----------------------------------\n"
)

# Add country statistics
country_stats <- read.csv("outputs/tables/habitat_by_country.csv")
for (i in 1:min(5, nrow(country_stats))) {
  summary_text <- paste0(summary_text,
                         i, ". ", country_stats$Country[i], ": ",
                         format(country_stats$Suitable_Area_km2[i], big.mark = ","), 
                         " km²\n")
}

summary_text <- paste0(summary_text, "\n",
                       "ECOLOGICAL INSIGHTS\n",
                       "-------------------\n",
                       "- Species prefers cold, high-altitude environments (optimal ~0°C)\n",
                       "- Strongly associated with mountain ranges (Himalayas, Karakoram, Pamir, Tian Shan)\n",
                       "- Temperature is the most important predictor (46% contribution)\n",
                       "- Habitat forms corridors along major mountain systems\n",
                       "- Potentially vulnerable to climate change due to temperature dependency\n\n",
                       
                       "CONSERVATION IMPLICATIONS\n",
                       "-------------------------\n",
                       "- Priority areas: China (813,555 km²), Mongolia (164,673 km²), Kyrgyzstan (151,181 km²)\n",
                       "- Habitat connectivity important across international borders\n",
                       "- Climate change monitoring recommended\n",
                       "- Focus on high-altitude protected areas\n\n",
                       
                       "FILES GENERATED\n",
                       "---------------\n",
                       "Data Files:\n",
                       "  - Occurrence data (cleaned)\n",
                       "  - Environmental layers (selected)\n",
                       "  - Background points\n",
                       "  - Final model data\n\n",
                       
                       "Model Outputs:\n",
                       "  - MaxEnt model object (.rds)\n",
                       "  - Habitat suitability raster (.tif)\n",
                       "  - Binary habitat map (.tif)\n",
                       "  - Model evaluation metrics\n",
                       "  - Cross-validation results\n\n",
                       
                       "Visualizations:\n",
                       "  - Occurrence maps\n",
                       "  - Correlation matrices\n",
                       "  - Response curves\n",
                       "  - ROC curves\n",
                       "  - Habitat suitability maps\n",
                       "  - Variable importance plots\n",
                       "  - Publication-quality figures\n\n",
                       
                       "================================================================================\n",
                       "Project completed successfully!\n",
                       "For more information, contact: Syed Inzimam Ali Shah\n",
                       "GitHub: https://github.com/Syedinzimam\n",
                       "================================================================================\n"
)

# Save summary
writeLines(summary_text, "PROJECT_SUMMARY.txt")
cat(summary_text)

cat("\n✓ Project summary saved to: PROJECT_SUMMARY.txt\n\n")

# ============================================================================
# 5. CREATE RESULTS TABLE FOR PUBLICATION
# ============================================================================
cat("Creating publication tables...\n")

# Table 1: Model Performance
table1 <- data.frame(
  Metric = c("Training AUC", "Testing AUC", "CV Mean AUC", "CV SD", 
             "Threshold", "Sensitivity", "Specificity"),
  Value = c(
    round(eval_results$AUC[1], 3),
    round(eval_results$AUC[2], 3),
    round(mean(cv_results$AUC), 3),
    round(sd(cv_results$AUC), 3),
    "0.0792",
    "0.90",
    "0.95"
  )
)

write.csv(table1, "outputs/tables/Table1_Model_Performance.csv", row.names = FALSE)

# Table 2: Variable Contribution
table2 <- data.frame(
  Variable = importance_df$Variable,
  Description = c(
    "Annual Mean Temperature",
    "Mean Diurnal Range",
    "Isothermality",
    "Temperature Seasonality",
    "Annual Precipitation",
    "Precipitation Seasonality",
    "Precipitation of Warmest Quarter",
    "Precipitation of Coldest Quarter"
  ),
  Contribution_Percent = round(importance_df$Contribution, 2)
)

write.csv(table2, "outputs/tables/Table2_Variable_Contribution.csv", row.names = FALSE)

cat("✓ Publication tables saved\n\n")

# ============================================================================
# 6. FINAL PROJECT STATISTICS
# ============================================================================
cat("=== FINAL PROJECT STATISTICS ===\n\n")

cat("Files created:\n")
cat("  Data files:", length(list.files("data", recursive = TRUE)), "\n")
cat("  Output files:", length(list.files("outputs", recursive = TRUE)), "\n")
cat("  Script files:", length(list.files("scripts", pattern = "\\.R$")), "\n")
cat("  Total maps:", length(list.files("outputs/maps", pattern = "\\.png$")), "\n")
cat("  Total tables:", length(list.files("outputs/tables", pattern = "\\.csv$")), "\n\n")

cat("=== DAY 10 COMPLETE ===\n")
cat("=== PROJECT COMPLETED SUCCESSFULLY ===\n\n")

cat("Next Steps:\n")
cat("1. Review all outputs in the outputs folder\n")
cat("2. Check PROJECT_SUMMARY.txt for comprehensive report\n")
cat("3. Use publication-quality figures for presentations/papers\n")
cat("4. Push project to GitHub repository\n")
cat("5. Consider writing README.md for documentation\n\n")

cat("Congratulations on completing your SDM project!\n")

