## How to Run: 
Open this task.Rmd file in RStudio (or another R Markdown environment) and click the Knit button to generate the output (HTML by default). Alternatively, run rmarkdown::render("filename.Rmd") in R to produce the report. 
Ensure the required packages are installed before knitting.

'Required Packages': This analysis uses the tidyverse package (for data manipulation and visualization) and the base stats functions for statistical tests. 
The knitr package is used to format tables. Install any missing packages with install.packages("tidyverse") (which includes ggplot2, dplyr, tidyr, etc.) and install.packages("knitr") if needed.

## Overview: 
This R Markdown simulates a field experiment to test two Facebook ad strategies to increase COVID-19 vaccine uptake.
Data Simulation: We generate a baseline survey of 5,000 U.S. participants with realistic demographic data and vaccine hesitancy responses. 
Participants are randomly assigned to one of three groups: a reason-based ad group, an emotion-based ad group, or a control group (no ad). 
We then simulate an endline survey for 4,500 participants (assuming some loss to follow-up) with data on whether they got vaccinated and their post-intervention attitudes. We assume the ad interventions have minimal effect sizes (small differences in outcomes between groups).

## Analysis: 
We merge the baseline, assignment, and endline datasets. We then compare vaccine uptake rates and vaccine attitude changes across the three groups. The analysis includes summary tables and bar plot visualizations to illustrate differences. We conduct basic statistical tests (e.g., chi-square test for uptake differences, and an ANOVA or t-test for attitude changes) to evaluate if the observed differences are beyond what might happen by chance.
Output: The report presents the simulated data analysis with annotated R code, tables of key results, and figures (bar plots) for vaccine uptake and attitude changes. All results are based on simulated data and for demonstration purposes only.
