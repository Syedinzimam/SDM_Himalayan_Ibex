Species Distribution Modeling: Himalayan Ibex (Capra sibirica)
Show Image
Show Image
Show Image

 Project Overview
This project implements a comprehensive Species Distribution Model (SDM) for the Himalayan Ibex (Capra sibirica) across Southeast Asia using MaxEnt (Maximum Entropy) modeling. The analysis identifies suitable habitats, evaluates environmental drivers, and provides conservation insights for this mountain-dwelling species.

Author: Syed Inzimam Ali Shah
Education: BS Zoology (Virtual University of Pakistan) and B.Sc. Forestry (Pakistan Forest Institute)
GitHub: @Syedinzimam
Duration: 15 days

 Objectives
Model the current distribution of Himalayan Ibex across Southeast Asia
Identify key environmental variables driving species distribution
Quantify suitable habitat area by country
Evaluate model performance using multiple validation techniques
Generate conservation-relevant insights
 Study Area
Geographic Extent: 60°E - 105°E, 25°N - 45°N
Countries Covered: Pakistan, Afghanistan, India, China, Nepal, Bhutan, Tajikistan, Kyrgyzstan, Kazakhstan, Mongolia, Uzbekistan

Key Mountain Ranges:

Himalayas
Karakoram
Hindu Kush
Pamir Mountains
Tian Shan
 Data Sources
Occurrence Data
Source: Global Biodiversity Information Facility (GBIF)
Records: 230 occurrence points (1883-2025)
Final Dataset: 50 points after cleaning and environmental filtering
Access: GBIF Capra sibirica
Environmental Data
Source: WorldClim v2.1 (Bioclimatic variables)
Resolution: 2.5 arc-minutes (~5 km)
Variables Selected: 8 bioclimatic variables (from 19 total)
Variable	Description	Contribution
bio1	Annual Mean Temperature	46.0%
bio2	Mean Diurnal Range	28.0%
bio3	Isothermality	10.0%
bio4	Temperature Seasonality	9.0%
bio12	Annual Precipitation	4.5%
bio15	Precipitation Seasonality	1.5%
bio18	Precip. Warmest Quarter	0.7%
bio19	Precip. Coldest Quarter	0.3%
 Methodology
1. Data Acquisition & Preparation
Downloaded occurrence data from GBIF API
Cleaned data: removed duplicates, NA coordinates, high uncertainty records
Generated 9,994 background points with 10km buffer from occurrences
2. Variable Selection
Calculated Pearson correlation matrix for 19 bioclimatic variables
Removed highly correlated variables (|r| > 0.7)
Selected 8 ecologically relevant, uncorrelated variables
3. MaxEnt Modeling
Algorithm: Maximum Entropy (MaxEnt)
Training/Testing Split: 80/20
Background Points: 9,994 random points
Settings: Default MaxEnt parameters with response curves and jackknife
4. Model Validation
Area Under Curve (AUC) for training and testing datasets
5-fold spatial cross-validation
Evaluation at presence locations
5. Habitat Analysis
Binary classification using spec_sens threshold
Area calculations by country
Suitability class categorization (Low, Moderate, High, Very High)
 Results
Model Performance
Metric	Value
Training AUC	0.977
Testing AUC	0.960
Cross-Validation AUC	0.966 ± 0.010
Performance Rating	EXCELLENT
Habitat Suitability
Total Suitable Habitat: 1,607,905 km²
Study Area Coverage: 17.7%
Mean Prediction at Presence: 0.796
Top Countries with Suitable Habitat
Rank	Country	Area (km²)	% of Total
1	China	813,555	50.6%
2	Mongolia	164,673	10.2%
3	Kyrgyzstan	151,181	9.4%
4	Kazakhstan	~100,000	~6%
5	India	~80,000	~5%
Environmental Preferences
Temperature: Optimal at ~0°C (cold, high-altitude environments)
Precipitation: Low to moderate (200-500 mm annually)
Elevation: High-altitude mountain ranges (3,000-5,500m)
Temperature Seasonality: Moderate variability preferred
 Repository Structure
SDM_Himalayan_Ibex/
├── data/
│   ├── raw/                    # Original GBIF downloads
│   ├── processed/              # Cleaned occurrence & environmental data
│   └── environmental/          # WorldClim rasters
├── scripts/
│   ├── day1_setup.R           # Project initialization
│   ├── day2_packages.R        # Package installation
│   ├── day3_gbif.R            # Data acquisition
│   ├── day4_worldclim.R       # Environmental data
│   ├── day5_correlation.R     # Variable selection
│   ├── day6_background.R      # Background point generation
│   ├── day7_maxent.R          # Model building
│   ├── day8_analysis.R        # Habitat analysis
│   ├── day9_validation.R      # Model validation
│   └── day10_final.R          # Final figures & report
├── outputs/
│   ├── maps/                  # 20 visualization files
│   ├── models/                # MaxEnt model objects & predictions
│   └── tables/                # 12 statistical summary tables
├── docs/
│   ├── project_log.txt        # Daily progress log
│   └── session_info_*.txt     # R session information
├── PROJECT_SUMMARY.txt        # Comprehensive project report
└── README.md                  # This file
 Installation & Usage
Prerequisites
r
# Required R version
R >= 4.0.0

# Required packages
install.packages(c(
  "dismo", "terra", "raster", "rgbif", "sf", "geodata",
  "ggplot2", "viridis", "rnaturalearth", "rnaturalearthdata",
  "tidyverse", "corrplot", "caret", "gridExtra", "rJava"
))
MaxEnt Setup
Download maxent.jar from MaxEnt Website
Place in R dismo package folder:
r
   file.path(system.file("java", package="dismo"), "maxent.jar")
Running the Analysis
r
# Set working directory
setwd("C:/SDM_Himalayan_Ibex")

# Run scripts sequentially (Day 1-10)
source("scripts/day1_setup.R")
source("scripts/day2_packages.R")
source("scripts/day3_gbif.R")
# ... continue through day10_final.R
 
 
 Key Visualizations
### 1. Occurrence Data Distribution
![Occurrence Map](./outputs/maps/occurrence_map_raw.png)

### 2. Habitat Suitability Model
![Habitat Suitability](./outputs/maps/Figure3_Final_Habitat_Map.png)

### 3. Variable Importance
![Variable Importance](./outputs/maps/variable_importance.png)

### 4. Response Curves
![Response Curves](./outputs/maps/response_curves_detailed.png)

### 5. Model Performance (ROC)
![ROC Curves](./outputs/maps/roc_curves.png)


 Key Findings
Ecological Insights
Temperature Dependency: Annual mean temperature is the strongest predictor (46% contribution), indicating high climate sensitivity
Habitat Corridors: Suitable habitat forms continuous corridors along major mountain ranges
Elevation Preference: Species strongly associated with high-altitude environments (>3000m)
Geographic Distribution: Concentrated in Central Asian mountain systems
Conservation Implications
Climate Vulnerability: Strong temperature dependency suggests high vulnerability to climate change
Transboundary Conservation: Habitat spans multiple countries, requiring international cooperation

Priority Areas:
Tibetan Plateau (China)
Tian Shan Mountains (China, Kyrgyzstan, Kazakhstan)
Pamir Mountains (Tajikistan, Afghanistan)

Monitoring Recommendations:
Long-term climate monitoring in core habitats
Population surveys in predicted suitable areas
Corridor connectivity assessment
 
Publications & Presentations
This project can be referenced in:
M.S. Wildlife Conservation applications
Conservation biology presentations
Species distribution modeling workshops
GitHub portfolio for data science roles

Suggested Citation:

Shah, S.I.A. (2025). Species Distribution Modeling of Himalayan Ibex 
(Capra sibirica) in Southeast Asia using MaxEnt. 
GitHub repository: https://github.com/Syedinzimam/SDM_Himalayan_Ibex
 
Acknowledgments
GBIF for providing open-access biodiversity data
WorldClim for high-resolution climate data
MaxEnt developers for the modeling software
Claude AI (Anthropic) for assistance in script development and methodology guidance
R Community for excellent open-source packages
 Contact
Syed Inzimam Ali Shah

GitHub: @Syedinzimam
Email: [inzimamsyed12@gmail.com]
LinkedIn: [https://www.linkedin.com/in/syed-inzimam]
 License
This project is licensed under the MIT License - see the LICENSE file for details.

 Related Projects

 [Biodiversity Hotspots Analysis in Pakistan](https://github.com/Syedinzimam/pakistan-biodiversity-analysis)
 Other wildlife conservation modeling projects
 References
Phillips, S. J., Anderson, R. P., & Schapire, R. E. (2006). Maximum entropy modeling of species geographic distributions. Ecological Modelling, 190(3-4), 231-259.
Fick, S. E., & Hijmans, R. J. (2017). WorldClim 2: new 1‐km spatial resolution climate surfaces for global land areas. International Journal of Climatology, 37(12), 4302-4315.
GBIF.org (2025). GBIF Occurrence Download. https://doi.org/10.15468/dl.[your-download-id]
Elith, J., et al. (2011). A statistical explanation of MaxEnt for ecologists. Diversity and Distributions, 17(1), 43-57.
 Future Improvements
 Incorporate future climate scenarios (2050, 2070)
 Add habitat connectivity analysis
 Include human footprint/disturbance layers
 Ensemble modeling with multiple algorithms
 Web application for interactive visualization
 Temporal analysis of habitat changes
Last Updated: November 2025
Project Status:  Complete

This project demonstrates proficiency in spatial ecology, species distribution modeling, R programming, data visualization, and conservation science - essential skills for graduate studies in Wildlife Conservation.

