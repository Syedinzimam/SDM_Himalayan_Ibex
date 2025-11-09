# ==============================================================================
# PROJECT: Species Distribution Modeling - Himalayan Ibex (Capra sibirica)
# AUTHOR: Syed Inzimam Ali Shah
# GITHUB: https://github.com/Syedinzimam
# DAY: 1 - Project Setup & Folder Structure
# DATE:  November-2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Set working directory to C drive
setwd("C:/")

# Create main project folder
project_name <- "SDM_Himalayan_Ibex"
dir.create(project_name, showWarnings = FALSE)

# Set project directory
project_dir <- paste0("C:/", project_name)
setwd(project_dir)

# Create folder structure
folders <- c(
  "data",
  "data/raw",
  "data/processed",
  "data/environmental",
  "scripts",
  "outputs",
  "outputs/maps",
  "outputs/models",
  "outputs/tables",
  "docs"
)

for (folder in folders) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
}

# Print folder structure
cat("✓ Project folder structure created successfully!\n\n")
cat("Project Directory:", project_dir, "\n\n")
cat("Folder Structure:\n")
list.dirs(project_dir, full.names = FALSE, recursive = TRUE)

# Create project log file
log_file <- "docs/project_log.txt"
cat("=== SDM PROJECT LOG ===\n", file = log_file)
cat("Project: Himalayan Ibex Distribution Modeling\n", file = log_file, append = TRUE)
cat("Species: Capra sibirica\n", file = log_file, append = TRUE)
cat("Region: Southeast Asia\n", file = log_file, append = TRUE)
cat("Start Date:", format(Sys.Date(), "%Y-%m-%d"), "\n", file = log_file, append = TRUE)
cat("Duration: 15 days\n", file = log_file, append = TRUE)
cat("Author: Syed Inzimam Ali Shah\n", file = log_file, append = TRUE)
cat("GitHub: Syedinzimam\n\n", file = log_file, append = TRUE)

cat("\n✓ Project log created at:", log_file, "\n")

# Save session info
session_file <- "docs/session_info_day1.txt"
capture.output(sessionInfo(), file = session_file)

cat("✓ Session info saved\n")
cat("\n=== SETUP COMPLETE ===\n")
cat("Next: Run Day 2 script for package installation\n")
