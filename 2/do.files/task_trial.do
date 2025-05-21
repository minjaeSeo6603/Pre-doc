*******************************************************
* Stata Data Task: Data Cleaning
* Name: Minjae Seo
* Date: May 15, 2025
*******************************************************

clear all
set more off
capture log close

/****************************
* Set globals
****************************/

* Adjust this path as per your local directory
if "`c(username)'" == "seominjae"{
	global root "/Users/seominjae/Desktop/Seo_Minjae"
	global figures "${root}/figures"
	global data_log "${root}/data/log"
	global data_raw "${root}/data/raw"
	global data_final "${root}/data/final"
}

log using "${data_log}/clean.log", replace

*-- 1. DATA IMPORT AND PREPARATION ------------------------------------------

* Import per-capita personal income data (1943-1962) from BEA
import delimited using "${data_raw}/pcinc.csv", varnames(1) case(lower)

* Drop aggregate rows (US total, regions, DC, Alaska, Hawaii) and footnote rows
drop if areaname == "United States"
drop if areaname == "District of Columbia"
drop if areaname == "Alaska" | areaname == "Hawaii 3/"
drop if inlist(areaname, "New England", "Mideast", "Great Lakes","Plains", "Southeast", "Southwest", "Rocky Mountain", "Far West 3/")
drop if _n > _N - 5

*change colnames							
forvalues i = 4/23 {
    local inc = 1939 + `i'   // e.g., v4 -> 1939+4 = 1943
    rename v`i' inc`inc'
}

* Reshape income data to long format (one observation per state-year)
destring inc1943 - inc1949, replace
reshape long inc, i(areaname) j(year)
rename inc pcinc
rename areaname state
order state year pcinc
label variable state "State name"
label variable year "Year"
label variable pcinc "Per-capita personal income"
keep state fips year pcinc 

* save the current data 
save "${data_raw}/pcinc_clean.dta",replace

* Import population data (1947-1964) from BEA
import delimited using "pop.csv", clear

* Drop same aggregate regions and non-states:
drop if areaname == "United States"
drop if areaname == "District of Columbia"
drop if areaname == "Alaska" | areaname == "Hawaii 3/"
drop if inlist(areaname, "New England", "Mideast", "Great Lakes", ///
                            "Plains", "Southeast", "Southwest", "Rocky Mountain", "Far West 3/")
drop if _n > _N - 5

*change colnames							
forvalues i = 4/21 {
    local inc = 1943 + `i'   // e.g., v4 -> 1943+4 = 1947
    rename v`i' inc`inc'
}

* Reshape income data to long format (one observation per state-year)
destring inc1947 - inc1964, replace
reshape long inc, i(areaname) j(year)
rename inc pop
rename areaname state
order state year pop
label variable state "State name"
label variable year "Year"
label variable pop "Population"
keep state fips year pop

* save the current data 
save "${data_raw}/pop_clean.dta",replace

use "${data_raw}/pcinc_clean.dta", clear
// Replacing with Null values 
preserve
keep state 
duplicates drop
tempfile states
save `states'
restore

clear
input year
1963
1964
end
cross using `states'

gen pcinc = .

append using "${data_raw}/pcinc_clean.dta"
duplicates drop state year, force
sort state year
save "${data_raw}/pcinc_clean.dta", replace

// Replacing with Null values 
use "${data_raw}/pop_clean.dta", clear

preserve
keep state 
duplicates drop
tempfile states
save `states'
restore

clear
input year
1943
1944
1945
1946
end
cross using `states'

gen pop = .

append using "${data_raw}/pop_clean.dta"
duplicates drop state year, force
sort state year
save "${data_raw}/pop_clean.dta", replace

* Merge income and population data by state and year to create base panel
use "${data_raw}/pcinc_clean.dta", clear
merge 1:1 state year using "${data_raw}/pop_clean.dta",keep(match) nogenerate
order state fips year pop pcinc
label variable state "State"
label variable year "Year"
label variable pcinc "Per-capita income (current $)"
label variable pop "Population"

* Create state-year identifier (e.g., "Alabama 1947")
gen str stateyear = state + string(year)
label variable stateyear "State-Year ID"

*-- 2. CALCULATE PREDICTED ALLOCATIONS --------------------------------------

* Allotment formula (from Federal Register, 31 Aug 1946) are implemented below:

* (i) Three-year moving average of state per-capita income (lagged by ~2 years)

* Ensure panel is sorted correctly
destring fips, replace // for numeric state id

*lagged income variables
by state: gen lag2 = pcinc[_n-2]   // 2 years ago
by state: gen lag3 = pcinc[_n-3]   // 3 years ago
by state: gen lag4 = pcinc[_n-4]   // 4 years ago

gen sm_pcinc = (lag4 + lag3 + lag2) / 3 if year >= 1947
label variable sm_pcinc "Smoothed PC income (avg of t-2, t-3, t-4)"

* (ii) National average of smoothed PC income for each year (excluding non-48 states)
sort year
by year: egen nat_sm_pcinc = mean(sm_pcinc)
label variable nat_sm_pcinc "National avg smoothed PC income"

* (iii) Index number = state smoothed PC income / national smoothed PC income
gen index = sm_pcinc / nat_sm_pcinc
label variable index "Income index (state/national)"

* (iv) Allotment percentage = 1 - 0.5 * index
gen allot_pct = 1 - 0.5 * index

* (v) Impose minimum 0.33 and maximum 0.75 on allotment percentage
replace allot_pct = 0.33 if allot_pct < 0.33
replace allot_pct = 0.75 if allot_pct > 0.75
label variable allot_pct "Allotment percentage (capped 0.33-0.75)"

* (vi) Weighted population = (allotment percentage)^2 * population
gen weighted_pop = allot_pct^2 * pop
label variable weighted_pop "Weighted population (allotment^2 * pop)"

* (vii) State allocation share = weighted_pop / sum(weighted_pop in year)
by year: egen total_wpop = total(weighted_pop)
gen alloc_share = weighted_pop / total_wpop
label variable alloc_share "State share of total allocation"
drop if year <1947
save "${data_raw}/pop_pcinc_first.dta"

* (viii) Predicted allocation = alloc_share * total federal appropriation that year
clear
input int(year) double(appr)
1947   75000000    
1948   75000000 
1949   75000000
1950   150000000
1951   85000000
1952   82500000
1953   75000000
1954   65000000
1955   96000000
1956   109800000
1957   123800000
1958   120000000
1959   147502832
1960   168589438
1961   160494355
1962   195741119
1963   195930360
1964   180166150
end
format %15.0fc appr
tempfile apprdata
save `apprdata', replace

* Merge appropriations into panel data
use "${data_raw}/pop_pcinc_first.dta",clear
merge m:1 year using `apprdata', keep(match master) nogenerate
label variable appr "Federal HB appropriation ($)"

* Compute predicted dollar allocation for each state-year
gen predicted = alloc_share * appr
label variable predicted "Predicted allocation ($)"

* (ix) Apply minimum dollar allotments: $100k minimum in 1948, $200k in 1949+ 
replace predicted = 100000 if year==1948 & predicted < 100000
replace predicted = 200000 if year>=1949 & predicted < 200000

* Clean up and format predicted values
format %14.2fc predicted

save "${data_raw}/pop_pcinc.dta",replace

*-- 3. AGGREGATE ACTUAL HILL-BURTON ALLOCATIONS BY STATE-YEAR ---------------

* Import Hill-Burton Project Register data (hbpr.txt) – state, year, federal funds
clear
import delimited using "${data_raw}/hbpr.txt", delim("\t") varnames(1) encoding("UTF-8")
keep state year hillburtonfunds
rename hillburtonfunds hbfunds
destring hbfunds, replace ignore(",")   // remove commas and convert to numeric
label variable hbfunds "Actual Hill-Burton funds ($)"

* The data includes projects for all years and areas; filter for 48 states and 1947-1964
replace year = 1900 + year 
drop if year < 1947 | year > 1964
drop if inlist(state, "Alaska", "Dist of Col", "Guam", "Hawaii", "Puerto Rico", "Virgin Islands")

* Collapse project-level data to total funds per state-year
collapse (sum) hbfunds, by(state year)
format %14.2fc hbfunds

* save actual data
save "${data_raw}/actual.dta",replace
use "${data_raw}/pop_pcinc.dta", clear
merge 1:1 state year using "${data_raw}/actual.dta", keep(match master) nogenerate
order state year predicted hbfunds pcinc pop
replace hbfunds = 0 if missing(hbfunds)   // set missing actual funds to 0 (no funding that year)
label variable hbfunds "Actual HB funds ($)"

* balanced data(Include all)
save "${data_final}/final.dta", replace

* Answer to Question 1
keep stateyear predicted hbfunds
order stateyear predicted hbfunds
save "${data_final}/balanced.dta", replace

log close
