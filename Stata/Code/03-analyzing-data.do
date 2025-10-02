* RRF 2025 - Analyzing Data Template	
*-------------------------------------------------------------------------------	
* Load data
*------------------------------------------------------------------------------- 
	
	*load analysis data 
	use "${data}/Final/TZA_CCT_analysis.dta", clear
	
*-------------------------------------------------------------------------------	
* Exploratory Analysis
*------------------------------------------------------------------------------- 
	
	* Area over treatment by districts 
	gr bar 	area_acre_w, ///
			over(treatment) ///
			by(district)

*-------------------------------------------------------------------------------	
* Final Analysis
*------------------------------------------------------------------------------- 


	* Bar graph by treatment for all districts 
	gr bar 	area_acre_w, ///
			over(treatment) ///
			by(district, row(1) title("Area cultivated by treatment") legend(position(6)) note("")) ///
			ytitle("Average area cultivated - acres") ///
			asy legend(rows(1) order(0 "Assginment:" 1 "Control" 2 "Treatment")) ///
			blabel(total, format(%9,1f)) ///
			subtitle(,position(6) bcolor(none))
			
			
	gr export "$outputs/fig1.png", replace	
	
	* Distribution of non food consumption by female headed hhs with means

	forvalues hh_head = 0/1 {
		su nonfood_cons_usd_w if female_head == `hh_head'
		local mean_`hh_head' = round(r(mean),0.01)
		
	}
	
	
	twoway	(kdensity nonfood_cons_usd_w if female_head == 1, color(purple)) ///
			(kdensity nonfood_cons_usd_w if female_head == 0, color(gray)) ///
			, ///
			xline(`mean_1', lcolor(purple) lpattern(dash)) ///
			xlabel(`mean_1', add) ///
			xline(`mean_0', lcolor(gray) lpattern(dash)) ///
			leg(order(0 "Household Head:" 1 "Female" 2 "Male" ) row(1) pos(6)) ///
			xtitle("Distribution") ///
			ytitle("Density") ///
			title("Distribution of non food consumption across household heads") ///
			note("Dashed lines represent the mean by gender of household head")
			
	gr export "$outputs/fig2.png", replace	
	
*-------------------------------------------------------------------------------	
* Summary stats
*------------------------------------------------------------------------------- 

	* defining globals with variables used for summary
	global sumvars 	hh_size n_child_5 n_elder read sick female_head livestock_now area_acre_w drought_flood crop_damage
	
	
	
	* Summary table - overall and by districts
	eststo all: 	estpost sum $sumvars
	eststo district_1: estpost sum $sumvars if district == 1
	eststo district_2: estpost sum $sumvars if district == 2
	eststo district_3: estpost sum $sumvars if district == 3
	
	
	* Exporting table in csv
	cd "${outputs}"
	esttab 	all district* ///
			using "summary_1.csv", replace ///
			refcat(hhsize "HH chars" drought_flood "Shocks" nolabel) ///
			label ///
			main(mean %6,2f) aux(sd) ///
			mtitle("Full Sample" "Kibaha" "Bagemoyos" "Chamwino") ///
			nonotes addn(Mean with standard deviation in parentheses.)
	
	* Also export in tex for latex
	
			
			
*-------------------------------------------------------------------------------	
* Balance tables
*------------------------------------------------------------------------------- 	
	
	* Balance (if they purchased cows or not)
	iebaltab 	${sumvars}, ///
				grpvar(treatment) ///
				rowvarlabels	///
				format(%9,2f)	///
				savecsv("${outputs}/balance") ///
				savetex("${outputs}/balance") ///
				nonote addnote("Significance: ***=.01 **=.05, *=.1") replace 		

				
*-------------------------------------------------------------------------------	
* Regressions
*------------------------------------------------------------------------------- 				
				
	* Model 1: Regress of food consumption value on treatment
	regress food_cons_usd_w treatment
	
	eststo mod1		// store regression results
	
	estadd local clustering "No"
	
	* Model 2: Add controls 
	
	regress food_cons_usd_w treatment crop_damage drought_flood
	
	eststo mod2
	
	estadd local clustering "No"
	
	* Model 3: Add clustering by village
	
	regress food_cons_usd_w treatment crop_damage drought_flood, vce(cluster vid)
	
	eststo mod3
	
	estadd local clustering "Yes"
	
	* Export results in tex
	cd "${outputs}"
	esttab 	mod1 mod2 mod3 ///
			using "regression.tex" , ///
			label ///
			b(%9,2f) se(%9,2f) ///
			nomtitles ///
			mgroup("Food Consumption", pattern(1 0 0 ) span) ///
			scalars("clustering Clustering") ///
			replace
			
*-------------------------------------------------------------------------------			
* Graphs: Secondary data
*-------------------------------------------------------------------------------			
		 
	use "${data}/Final/TZA_amenity_analysis.dta", clear
	
	* create a variable to highlight the districts in sample
	gen in_sample = inlist(district, 1, 3, 6)
	
	
	
	* Separate indicators by sample
	separate n_school, by(in_sample)
	separate n_medical, by(in_sample)
	
	
	* Graph bar for number of schools by districts
		gr hbar 	n_school0 n_school1, ///
				nofill ///
				over(district, sort(n_school)) ///
				legend(order(0 "Sample:" 1 "Out" 2 "In") row(1)  pos(6)) ///
				ytitle("No. of Schools") ///
				name(g1, replace)
				
	* Graph bar for number of medical facilities by districts				
	gr hbar 	n_medical0 n_medical1, ///
				nofill ///
				over(district, sort(n_medical)) ///
				legend(order(0 "Sample:" 1 "Out" 2 "In") row(1)  pos(6)) ///
				ytitle("No. of Medical Facilities") ///
				name(g2, replace)
				
	grc1leg2 	g1 g2, ///
				row(1) legend(g1) ///
				ycommon xcommon ///
				title("Access to amenities: By District", size(medium))
			
	
	gr export "$outputs/fig3.png", replace		

****************************************************************************end!			
