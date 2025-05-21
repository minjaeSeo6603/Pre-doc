# 1.The effectiveness of different Facebook ad campaigns in increasing COVID-19 vaccine uptake

## How to Run 
1. Open this code.Rmd file in RStudio (or another R Markdown environment)
2. Click the Knit button to generate the output (HTML by default). Alternatively, run rmarkdown::render("filename.Rmd") in R to produce the report. 
Ensure the required packages are installed before knitting.

``Required Packages``: This analysis uses the tidyverse package (for data manipulation and visualization) and the base stats functions for statistical tests. 
The knitr package is used to format tables. 

Install any missing packages with install.packages("tidyverse") (which includes ggplot2, dplyr, tidyr, etc.) and install.packages("knitr") if needed.

3. If you render code.Rmd, then you can also visualize this in PDF.

## Overview
This R Markdown simulates a field experiment to test two Facebook ad strategies to increase COVID-19 vaccine uptake. 

1. We generate a baseline survey of 5,000 U.S. participants with realistic demographic data and vaccine hesitancy responses.
2. Participants are randomly assigned to one of three groups: a reason-based ad group, an emotion-based ad group, or a control group (no ad).
3. We then simulate an endline survey for 4,500 participants (assuming some loss to follow-up) with data on whether they got vaccinated and their post-intervention attitudes.
4. We assume the ad interventions have minimal effect sizes (small differences in outcomes between groups).

## Analysis
1. We merge the baseline, assignment, and endline datasets. We then compare vaccine uptake rates and vaccine attitude changes across the three groups.
2. The analysis includes summary tables and bar plot visualizations to illustrate differences.
3. We conduct basic statistical tests (e.g., chi-square test for uptake differences, and an ANOVA or t-test for attitude changes) to evaluate if the observed differences are beyond what might happen by chance.


# 2.Investigating the allocation of Hill-Burton funding across states

## Overview:
The Hill-Burton Hospital Survey and Construction Act of 1946 aimed to expand hospital
infrastructure by providing federal funds to states for hospital construction, conditional on
states matching funds and providing a share of free care. Each year, Congress appropriated
funds to Hill-Burton; these were apportioned to states using a formula intended to target need
by incorporating state population and income levels. According to contemporary accounts,
the original legislation authorized $75 million annually for five years, later increased to
$150 million per year in 1949.

## Research-Specific Questions: 

1. The project aimed to investigate how hospital construction funds were allocated under
The Hill-Burton program, a large-scale hospital construction program that started in the 1940s,
to analyze the nature of competition in the hospital industry.

2.  The goal of this task is to investigate whether the non-linearities in the formula
were binding, and whether the state-level allocation formula was predictive of actual funding
allocations.

## Repo Contents
- `Do files\`: Data Cleaning[`tasktrial.do`], Data Analysis[`analysis.do`]
- `Figures\`: Figures/Tables from `Analysis.do` file
- `data\`: Refer to `Raw\`[Raw Dataset] and `Final\`[`Balanced.dta`,`Final.dta`]
- `Writeup.pdf`: PDF documentation Write-up file for the analysis.

## Highlighting Current Results
Using a newly constructed panel dataset, we find that the Hill-Burton state allocation formula can largely explain the distribution of hospital construction funds across states during 1947–1964.
States’ predicted shares, derived from population and income data, track closely with actual funding receipts. This indicates that the Hill-Burton program operated rules-based, with few major deviations from the formula. 
The minimum allotment percentage of 0.33 was frequently binding for high-income states, ensuring each state received at least a small portion of funds, whereas the maximum of 0.75 was never reached. 
implying no state’s need was high enough to claim an outsized majority of funds under the formula.

