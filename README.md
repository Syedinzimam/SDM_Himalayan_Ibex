# Species Distribution Modeling: Himalayan Ibex (*Capra sibirica*)

## Project Overview
This project presents a comprehensive Species Distribution Model (SDM) for the Himalayan Ibex (*Capra sibirica*) across Southeast and Central Asia using the MaxEnt (Maximum Entropy) algorithm. The model identifies suitable habitats, evaluates key environmental variables, and provides conservation insights relevant to climate-driven species distributions.

**Author:** Syed Inzimam Ali Shah  
**Education:** BS Zoology (Virtual University of Pakistan) & B.Sc. Forestry (Pakistan Forest Institute)  
**GitHub:** @Syedinzimam  
**Project Duration:** 15 days  

---

## Objectives
- Model the current distribution of Himalayan Ibex across Southeast & Central Asia  
- Identify key environmental drivers shaping species distribution  
- Quantify suitable habitat area by country  
- Evaluate model performance using multiple validation approaches  
- Generate conservation-relevant insights  

---

## Study Area
**Geographic Extent:** 60°E–105°E, 25°N–45°N  

**Countries Covered:**  
Pakistan, Afghanistan, India, China, Nepal, Bhutan, Tajikistan, Kyrgyzstan, Kazakhstan, Mongolia, Uzbekistan

**Major Mountain Ranges:**
- Himalayas  
- Karakoram  
- Hindu Kush  
- Pamir Mountains  
- Tian Shan  

---

## Data Sources

### **Occurrence Data**
- **Source:** Global Biodiversity Information Facility (GBIF)  
- **Initial Records:** 230 points (1883–2025)  
- **Final Dataset:** 50 points after cleaning  
- **Access:** GBIF *Capra sibirica*  

### **Environmental Data**
- **Source:** WorldClim v2.1  
- **Resolution:** 2.5 arc-min (~5 km)  
- **Selected Variables (8 total):**

| Variable | Description | Contribution |
|---------|-------------|--------------|
| bio1 | Annual Mean Temperature | 46.0% |
| bio2 | Mean Diurnal Range | 28.0% |
| bio3 | Isothermality | 10.0% |
| bio4 | Temperature Seasonality | 9.0% |
| bio12 | Annual Precipitation | 4.5% |
| bio15 | Precipitation Seasonality | 1.5% |
| bio18 | Precipitation Warmest Quarter | 0.7% |
| bio19 | Precipitation Coldest Quarter | 0.3% |

---

## Methodology

### **1. Data Acquisition & Preparation**
- Downloaded occurrence data via GBIF API  
- Cleaned duplicates, NA coordinates, uncertain records  
- Generated 9,994 background points (10 km buffer)

### **2. Variable Selection**
- Computed correlation matrix (19 variables)  
- Removed collinearity (|r| > 0.7)  
- Selected 8 ecologically relevant predictors  

### **3. MaxEnt Modeling**
- Algorithm: Maximum Entropy  
- Train/Test split: 80/20  
- Background points: 9,994  
- Default MaxEnt settings with response curves & jackknife  

### **4. Model Validation**
- AUC (Train & Test)  
- 5-fold spatial cross-validation  
- Evaluation at presence locations  

### **5. Habitat Analysis**
- Threshold: `spec_sens`  
- Suitability classes (Low → Very High)  
- Area calculations by country  

---

## Results

### **Model Performance**

| Metric | Value |
|--------|--------|
| Training AUC | **0.977** |
| Testing AUC | **0.960** |
| Cross-Validation AUC | **0.966 ± 0.010** |
| Rating | **EXCELLENT** |

### **Habitat Suitability**
- **Total Suitable Habitat:** 1,607,905 km²  
- **Coverage of Study Area:** 17.7%  
- **Mean Prediction at Presence:** 0.796  

### **Top Countries With Suitable Habitat**

| Rank | Country | Area (km²) | % of Total |
|------|---------|------------|------------|
| 1 | China | 813,555 | 50.6% |
| 2 | Mongolia | 164,673 | 10.2% |
| 3 | Kyrgyzstan | 151,181 | 9.4% |
| 4 | Kazakhstan | ~100,000 | ~6% |
| 5 | India | ~80,000 | ~5% |

### **Environmental Preferences**
- Optimal temp ~0°C (cold alpine conditions)  
- Precipitation 200–500 mm annually  
- Elevation 3,000–5,500 m  
- Moderate temperature seasonality preferred  

---

## Repository Structure
```

SDM_Himalayan_Ibex/
├── data/
│   ├── raw/
│   ├── processed/
│   └── environmental/
├── scripts/
│   ├── day1_setup.R
│   ├── day2_packages.R
│   ├── day3_gbif.R
│   ├── day4_worldclim.R
│   ├── day5_correlation.R
│   ├── day6_background.R
│   ├── day7_maxent.R
│   ├── day8_analysis.R
│   ├── day9_validation.R
│   └── day10_final.R
├── outputs/
│   ├── maps/
│   ├── models/
│   └── tables/
├── docs/
│   ├── project_log.txt
│   └── session_info_*.txt
├── PROJECT_SUMMARY.txt
└── README.md

````

---

## Installation & Usage

### **Requirements**
```r
R >= 4.0.0
````

### **Install Packages**

```r
install.packages(c(
  "dismo", "terra", "raster", "rgbif", "sf", "geodata",
  "ggplot2", "viridis", "rnaturalearth", "rnaturalearthdata",
  "tidyverse", "corrplot", "caret", "gridExtra", "rJava"
))
```

### **MaxEnt Setup**

Download **maxent.jar** from the MaxEnt website and place it in:

```r
file.path(system.file("java", package="dismo"), "maxent.jar")
```

### **Run Full Workflow**

```r
setwd("C:/SDM_Himalayan_Ibex")

source("scripts/day1_setup.R")
source("scripts/day2_packages.R")
source("scripts/day3_gbif.R")
...
source("scripts/day10_final.R")
```

---

## Key Findings

### **Ecological Insights**

* Strong temperature dependency → climate-sensitive
* Continuous habitat corridors along major mountain systems
* Species associated with high-altitude alpine zones
* Distribution concentrated in Central Asian mountains

### **Conservation Implications**

* Vulnerable to climate warming
* Needs transboundary conservation efforts
* Priority regions:

  * Tibetan Plateau (China)
  * Tian Shan (China–Kyrgyzstan–Kazakhstan)
  * Pamir Mountains (Tajikistan–Afghanistan)

---

## Citation

**Shah, S.I.A. (2025).** *Species Distribution Modeling of Himalayan Ibex (Capra sibirica) using MaxEnt.*
GitHub Repository: [https://github.com/Syedinzimam/SDM_Himalayan_Ibex](https://github.com/Syedinzimam/SDM_Himalayan_Ibex)

---

## Acknowledgments

* GBIF (occurrence data)
* WorldClim (environmental variables)
* MaxEnt developers
* Claude AI (assistance in scripting workflow)
* R Open-Source Community

---

## Contact

**Syed Inzimam Ali Shah**
GitHub: @Syedinzimam
Email: [inzimamsyed12@gmail.com](mailto:inzimamsyed12@gmail.com)
LinkedIn: [https://www.linkedin.com/in/syed-inzimam](https://www.linkedin.com/in/syed-inzimam)

---

## License

This project is released under the **MIT License**.

---

## Related Projects

* **Biodiversity Hotspots Analysis in Pakistan**
  [https://github.com/Syedinzimam/pakistan-biodiversity-analysis](https://github.com/Syedinzimam/pakistan-biodiversity-analysis)

---

## References

* Phillips et al. (2006). *Maximum entropy modeling of species geographic distributions.*
* Fick & Hijmans (2017). *WorldClim 2.*
* Elith et al. (2011). *A statistical explanation of MaxEnt.*
* GBIF.org (2025). Occurrence Download.

---

**Last Updated:** November 2025
**Project Status:**  Complete

This project demonstrates strong skills in species distribution modeling, spatial ecology, R programming, environmental data processing, and conservation science—key competencies for graduate study in Wildlife Conservation.

```


