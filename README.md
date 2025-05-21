## The effectiveness of different Facebook ad campaigns in increasing COVID-19 vaccine uptake

# 1. 

### How to Run 
1. Open this code.Rmd file in RStudio (or another R Markdown environment)
2. Click the Knit button to generate the output (HTML by default). Alternatively, run rmarkdown::render("filename.Rmd") in R to produce the report. 
Ensure the required packages are installed before knitting.

``Required Packages``: This analysis uses the tidyverse package (for data manipulation and visualization) and the base stats functions for statistical tests. 
The knitr package is used to format tables. 

Install any missing packages with install.packages("tidyverse") (which includes ggplot2, dplyr, tidyr, etc.) and install.packages("knitr") if needed.

3. If you render code.Rmd, then you can also visualize this in PDF.

### Overview
This R Markdown simulates a field experiment to test two Facebook ad strategies to increase COVID-19 vaccine uptake. 

1. We generate a baseline survey of 5,000 U.S. participants with realistic demographic data and vaccine hesitancy responses.
2. Participants are randomly assigned to one of three groups: a reason-based ad group, an emotion-based ad group, or a control group (no ad).
3. We then simulate an endline survey for 4,500 participants (assuming some loss to follow-up) with data on whether they got vaccinated and their post-intervention attitudes.
4. We assume the ad interventions have minimal effect sizes (small differences in outcomes between groups).

### Analysis
1. We merge the baseline, assignment, and endline datasets. We then compare vaccine uptake rates and vaccine attitude changes across the three groups.
2. The analysis includes summary tables and bar plot visualizations to illustrate differences.
3. We conduct basic statistical tests (e.g., chi-square test for uptake differences, and an ANOVA or t-test for attitude changes) to evaluate if the observed differences are beyond what might happen by chance.

## Another Research on Stata
#2
## This study constructs a panel of 48 U.S. states from 1947–1964 and compares the formula’s predicted state allocations to actual federal Hill-Burton funding.
