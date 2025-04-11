## setting up environment 
rm(list = ls(all.names = TRUE)) # clear all objects including hidden objects
gc() # free up memory and report the memory usage 

# Set working directory

# Install sufficient packages based off the command below
# install.packages(c("tidyverse","knitr","readr")) # uncomment this code to install the packages

# Attach packages
library(tidyverse) # includes ggplot2, for data visualization. dplyr, for data manipulation
library(knitr)       # for kable table formatting
library(xtable)
library(stargazer)
set.seed(123)        # fix the random seed for reproducibility

# Number of participants
N <- 5000

# Unique IDs
participant_id <- 1:N

# Age: simulate with a distribution from 18 to 90 (skewing toward middle-aged)
age <- round(rnorm(N, mean = 50, sd = 18))
age[age < 18] <- 18   # enforce minimum age 18
age[age > 90] <- 90   # cap maximum age at 90

# Gender
gender <- sample(c("Male", "Female"), N, replace = TRUE, prob = c(0.49, 0.51))

# Race/Ethnicity: simulate categories with rough US proportions
race <- sample(c("White", "Black", "Hispanic", "Asian", "Other"),
               N, replace = TRUE, prob = c(0.60, 0.13, 0.18, 0.06, 0.03))

# Income: categorize income as Low, Medium, High (roughly 30/40/30 split)
income <- sample(c("Low", "Medium", "High"), N, replace = TRUE, prob = c(0.3, 0.4, 0.3))

# Education: education level distribution (approximate)
education <- sample(c("High School or less", "Some College", "Bachelor's or higher"),
                    N, replace = TRUE, prob = c(0.4, 0.3, 0.3))

# Region: Northeast, Midwest, South, West with realistic proportions
region <- sample(c("Northeast", "Midwest", "South", "West"),
                 N, replace = TRUE, prob = c(0.18, 0.22, 0.37, 0.23))

# Vaccine hesitancy questions at baseline:
# Q1: Concern about side effects (1=not concerned, 5=very concerned)
# Q2: Lack of trust in vaccine (1=strongly disagree (trust vaccine), 5=strongly agree (do not trust))
# We simulate these with a bias toward some hesitancy (higher values) since unvaccinated population tends to have more concerns.
hesitancy_q1 <- sample(1:5, N, replace = TRUE, prob = c(0.10, 0.20, 0.25, 0.25, 0.20))
hesitancy_q2 <- sample(1:5, N, replace = TRUE, prob = c(0.10, 0.20, 0.25, 0.25, 0.20))

# Combine into a baseline data frame
baseline <- data.frame(
  id = participant_id,
  age = age,
  gender = gender,
  race = race,
  income = income,
  education = education,
  region = region,
  hesitancy_q1 = hesitancy_q1,
  hesitancy_q2 = hesitancy_q2
)

# Peek at the first few rows of the baseline data
head(baseline, 5)

# Write to csv
# write.csv(baseline, "./data/baseline.csv") # uncomment it to save the baseline data

# Define the three groups
groups <- c("Reason Ad", "Emotion Ad", "Control")

# Randomly assign each participant to one of the groups (approximately 1/3 each)
assignment <- data.frame(
  id = participant_id,
  group = sample(groups, N, replace = TRUE, prob = c(1/3, 1/3, 1/3))
)

# Verify the distribution of participants in each group
table(assignment$group)

# Write to csv
write.csv(assignment, "./data/assignment.csv") # uncomment it to save the baseline data

# Merge baseline and assignment to check baseline comparability by group
baseline_assign <- merge(baseline, assignment, by = "id")
# Compute a combined hesitancy score (average of Q1 and Q2 for a quick check)
baseline_assign$hesitancy_score <- (baseline_assign$hesitancy_q1 + baseline_assign$hesitancy_q2) / 2

# Check mean hesitancy score by group
baseline_assign %>% group_by() %>%
  summarize(mean_hesitancy = mean(hesitancy_score))

# Write to csv
# write.csv(baseline_assign, "./data/baseline_assign.csv") # uncomment it to save the baseline data

# Determine which participants respond at endline (4500 out of 5000)
endline_ids <- sample(participant_id, size = 4500, replace = FALSE)
endline_ids <- sort(endline_ids)  # sort just for consistency (not required)

# Create a data frame for endline responses
endline <- data.frame(id = endline_ids)

# Merge baseline + assignment info to endline respondents for easier simulation of outcomes
# This gives each responding participant their baseline data and group assignment
endline <- endline %>% 
  left_join(baseline, by = "id") %>%      # add baseline demographics and attitudes
  left_join(assignment, by = "id")        # add group assignment

# Simulate vaccination outcome (0/1) with minimal treatment effect:
# We'll calculate a probability of vaccination for each person.
# Base probability depending on baseline hesitancy:
# (We use the average of Q1 and Q2 as a combined hesitancy measure for simplicity.)
endline$baseline_hesitancy_score <- (endline$hesitancy_q1 + endline$hesitancy_q2) / 2

# Define a mapping from baseline hesitancy to base vaccination probability for control:
# For hesitancy score 1 -> ~90% chance, 5 -> ~15% chance, linearly interpolate for 2-4.
# We can use a simple linear model: p = 1 - 0.2*(score - 1) - some offset
# Or define manually:
base_prob <- function(hes_score) {
  if (hes_score <= 1) return(0.90)
  if (hes_score <= 2) return(0.75)
  if (hes_score <= 3) return(0.60)
  if (hes_score <= 4) return(0.35)
  return(0.15)
}

# Apply base probabilities for control scenario
endline$base_vacc_prob <- sapply(endline$baseline_hesitancy_score, base_prob)

# Apply treatment effect adjustments to probability:
# Small increases for treatment groups
endline <- endline %>%
  mutate(vacc_prob = case_when(
    group == "Reason Ad"  ~ pmin(1, base_vacc_prob + 0.05),  # +5% for reason-based ad
    group == "Emotion Ad" ~ pmin(1, base_vacc_prob + 0.03),  # +3% for emotion-based ad
    group == "Control"    ~ base_vacc_prob
  ))

# Now determine vaccinated outcome by drawing from a Bernoulli distribution with probability = vacc_prob
endline$vaccinated <- rbinom(n = nrow(endline), size = 1, prob = endline$vacc_prob)

# Simulate endline hesitancy questions (Q1 and Q2) with possible slight improvements for treatment groups.
# We'll use the baseline values as a starting point and add random change.
# For control: assume no systematic change (mean change ~ 0).
# For reason-based: assume a small decrease in hesitancy (mean change ~ -0.2 on the 1-5 scale).
# For emotion-based: assume a smaller decrease (mean change ~ -0.1).
# We'll add random noise (normal with sd ~ 0.5) so most people change by at most 1 point.
endline <- endline %>%
  mutate(
    # Change in Q1
    q1_change = case_when(
      group == "Reason Ad"  ~ rnorm(n(), mean = -0.2, sd = 0.5),
      group == "Emotion Ad" ~ rnorm(n(), mean = -0.1, sd = 0.5),
      group == "Control"    ~ rnorm(n(), mean =  0.0, sd = 0.5)
    ),
    # Change in Q2
    q2_change = case_when(
      group == "Reason Ad"  ~ rnorm(n(), mean = -0.2, sd = 0.5),
      group == "Emotion Ad" ~ rnorm(n(), mean = -0.1, sd = 0.5),
      group == "Control"    ~ rnorm(n(), mean =  0.0, sd = 0.5)
    ),
    # Apply changes to baseline values to get endline responses, and keep within 1-5 bounds
    hesitancy_q1_end = pmin(pmax(round(hesitancy_q1 + q1_change), 1), 5),
    hesitancy_q2_end = pmin(pmax(round(hesitancy_q2 + q2_change), 1), 5)
  )

# Take a peek at the first few rows of the endline dataset
head(endline, 5)

# Select and arrange the final endline data columns of interest
endline <- endline %>%
  select(id, group, vaccinated, hesitancy_q1_end, hesitancy_q2_end)

# Write to csv
# write.csv(endline, "./data/endline.csv") # uncomment it to save the endline data

# Merge baseline and assignment with endline (which already has group) to get baseline info for responders
analysis_data <- endline %>%
  left_join(baseline, by = "id")  # brings in age, gender, baseline hesitancy, etc.

# For clarity, let's rename the baseline and endline attitude columns differently
analysis_data <- analysis_data %>%
  rename(hesitancy_q1_baseline = hesitancy_q1,
         hesitancy_q2_baseline = hesitancy_q2,
         hesitancy_q1_endline  = hesitancy_q1_end,
         hesitancy_q2_endline  = hesitancy_q2_end)

# Check the size of the merged data and a snippet
dim(analysis_data)    # should be 4500 x (columns)
head(analysis_data, 3)

# Write to csv
# write.csv(analysis_data, "./data/analysis_data.csv") # uncomment it to save merged data

# Calculate number and percentage of vaccinated participants by group
uptake_summary <- analysis_data %>%
  group_by(group) %>%
  summarize(
    n_participants = n(),
    n_vaccinated = sum(vaccinated),
    percent_vaccinated = mean(vaccinated) * 100  # mean of 0/1 gives proportion, *100 for percentage
  )

# Display the summary table of vaccine uptake by group
kable(uptake_summary, digits = 1, col.names = c("Group", "N (responded)", "Vaccinated (N)", "Vaccinated (%)"))

# Bar plot of vaccination rate by group
ggplot(uptake_summary, aes(x = group, y = percent_vaccinated, fill = group)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.1f%%", percent_vaccinated)), vjust = -0.5) +
  labs(title = "COVID-19 Vaccine Uptake by Experimental Group",
       y = "Vaccinated (%)",
       x = "Experimental Group") +
  theme_minimal() +
  theme(legend.position = "none")

vacc_table <- table(analysis_data$group, analysis_data$vaccinated)
vacc_table  # show the table of counts

# Chi-square test for difference in proportions
chi_test <- chisq.test(vacc_table)
chi_test$p.value

# Logistic regression of vaccinated outcome on group
logit_model <- glm(vaccinated ~ group, data = analysis_data, family = binomial)
summary(logit_model)

# Compute overall hesitancy score at baseline and endline (average of Q1 and Q2)
analysis_data <- analysis_data %>%
  mutate(hesitancy_score_baseline = (hesitancy_q1_baseline + hesitancy_q2_baseline) / 2,
         hesitancy_score_endline  = (hesitancy_q1_endline + hesitancy_q2_endline) / 2,
         attitude_change = hesitancy_score_endline - hesitancy_score_baseline  # change (positive means became more hesitant)
  )

# Calculate mean baseline and endline hesitancy scores by group
attitude_summary <- analysis_data %>%
  group_by(group) %>%
  summarize(
    mean_hesitancy_baseline = mean(hesitancy_score_baseline),
    mean_hesitancy_endline  = mean(hesitancy_score_endline),
    mean_change = mean(attitude_change)
  )

# Display the attitude summary table
kable(attitude_summary, digits = 2, col.names = c("Group", "Baseline Hesitancy (mean)", "Endline Hesitancy (mean)", "Mean Change"))

# Prepare data for plotting baseline vs endline means by group
attitude_plot_data <- attitude_summary %>%
  select(Group = group, Baseline = mean_hesitancy_baseline, Endline = mean_hesitancy_endline) %>%
  pivot_longer(cols = c("Baseline", "Endline"), names_to = "Time", values_to = "MeanHesitancy")

# Bar plot of mean hesitancy at baseline vs endline for each group
ggplot(attitude_plot_data, aes(x = Group, y = MeanHesitancy, fill = Time)) +
  geom_col(position = "dodge", width = 0.6) +
  geom_text(aes(label = sprintf("%.2f", MeanHesitancy)), 
            position = position_dodge(width = 0.6), vjust = -0.5, size = 3) +
  labs(title = "Vaccine Hesitancy Score by Group: Baseline vs Endline",
       x = "Group", y = "Average Hesitancy (1=low, 5=high)",
       fill = "Survey") +
  theme_minimal()

# ANOVA to test if mean attitude change differs by group
anova_result <- aov(attitude_change ~ group, data = analysis_data)
summary(anova_result)

# Pairwise t-tests for attitude change between groups (no adjustment for multiple comparisons here for simplicity)
pairwise.t.test(analysis_data$attitude_change, analysis_data$group, paired = FALSE, p.adjust.method = "none")