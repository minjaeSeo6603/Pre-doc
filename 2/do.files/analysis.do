*******************************************************
* Stata Data Task: Data Visualization & Analysis 
* Name: Minjae Seo
* Date: May 15, 2025
*******************************************************

clear all
set more off
capture log close

/****************************
* Set globals
****************************/
if "`c(username)'" == "seominjae" {
	global root "/Users/seominjae/Desktop/Seo_Minjae"
	global figures "${root}/figures"
	global data_log "${root}/data/log"
	global data_raw "${root}/data/raw"
	global data_final "${root}/data/final"
}

log using "${data_log}/analysis.log", replace

use "${data_final}/final.dta", clear

* Scatter plot
twoway ///
    (scatter hbfunds predicted, ///
        msymbol(circle_hollow) mcolor(navy%40) msize(medium) ///
        legend(label(1 "State-Year Observations"))) ///
    (lfit hbfunds predicted, ///
        lcolor(blue) lpattern(solid) lwidth(medium) ///
        legend(label(2 "Linear Fit"))) ///
    (function y = x, range(0 2e7) ///
        lpattern(dash) lcolor(maroon) lwidth(medium) ///
        legend(label(3 "45-Degree Reference"))), ///
    title("Predicted vs. Actual Hill-Burton Allocations", size(medsmall)) ///
    subtitle("48 Contiguous U.S. States, 1947–1964", size(small)) ///
    caption("Note: Each point represents a state-year. Red dashed line shows y = x; blue line is best linear fit.", size(vsmall)) ///
    xtitle("Predicted Allocation (USD)", size(small)) ///
    ytitle("Actual Allocation (USD)", size(small)) ///
    xlabel(0(5e6)2e7, format(%9.0fc)) ///
    ylabel(0(5e6)2e7, format(%9.0fc)) ///
    legend(order(1 2 3) position(20) ring(0) size(small)) ///
    aspect(1) ///
    xscale(range(0 20000000)) ///
    yscale(range(0 20000000)) ///
    graphregion(color(white)) ///
    plotregion(style(none))

graph export "${figures}/predicted_vs_actual_enhanced.png", replace width(3000)

*  Univariate Regression with Fixed Effects(State and time fixed)

* State and year FE + robust SE
gen ln_hbfunds = log(hbfunds)
gen ln_predicted = log(predicted)

reghdfe hbfunds predicted, absorb(fips year) vce(robust)
reghdfe hbfunds predicted, absorb(fips year) vce(cluster fips)

estimates store fe

* Same with hetereskedascity cluster-robust SE (by state)
reghdfe ln_hbfunds ln_predicted, absorb(fips year) vce(robust)
reghdfe ln_hbfunds ln_predicted, absorb(fips year) vce(cluster fips)

estimates store log_fe

* For outputting, export to LaTeX or view in console
 esttab fe log_fe using "${figures}/fe_table.tex", ///
    title("Regression of Actual on Predicted Hill-Burton Allocations") ///
    label se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(r2 N, fmt(3 0) labels("R-squared" "Observations")) ///
    order(predicted) ///
    mtitles("Robust SEs" "Clustered SEs by State") ///
    replace

* Check binding at min/max thresholds in allocation percentage
gen byte min_allot = (abs(allot_pct - 0.33) < 0.001) // for floating
gen byte max_allot = (abs(allot_pct - 0.75) < 0.001)

collapse (sum) min_allot max_allot, by(year)
format min_allot max_allot %8.0f

disp "Years with states hitting 0.33 minimum:"
list year min_allot if min_allot > 0

disp "Years with states hitting 0.75 maximum:"
list year max_allot if max_allot > 0

* Count total instances
sum min_allot
scalar total_min = r(sum)

sum max_allot
scalar total_max = r(sum)

di "Total instances below 0.33 (min cap): " total_min
di "Total instances above 0.75 (max cap): " total_max

log close
