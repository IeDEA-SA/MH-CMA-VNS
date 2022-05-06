**** PLOT CMA OF CLUSTERS  

	* Data: included in trajectory analysis if at least 12 quaters of data 
		use "$clean/CMAq_c", clear
		count if c4 !=. //	32,254
		reshape long cma_q, i(patient) j(q)
		replace q = q-.5
		
	* C2
		tab c2 if q ==1
		twoway ///
			lpoly cma_q q if c3 ==1, bwidth(2) color("$green")   || /// 
			lpoly cma_q q if c3 ==2, bwidth(2) color("$red") /// 
				scheme(cleanplots) xtitle("Time since baseline, years", size(*1.3)) ytitle("Mean CMA, %", size(*1.3))  ///
				name("c2", replace)  ysize(4) xsize(4.5) ///
				ylab(0(10)100, labsize(*1.3)) xlab(1 "0" 4 "1" 8 "2" 12 "3" 16 "4" 20 "5", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
		
	* C3
		tab c3 if q ==1
		twoway ///
			lpoly cma_q q if c3 ==1, bwidth(2) color("$green")   || /// 
			lpoly cma_q q if c3 ==2, bwidth(2) color("$blue") || /// 			
			lpoly cma_q q if c3 ==3, bwidth(2) color("$red") /// 
				scheme(cleanplots) xtitle("Time since baseline, years", size(*1.3)) ytitle("Mean CMA, %", size(*1.3))  ///
				name("c3", replace)  ysize(4) xsize(4.5) ///
				ylab(0(10)100, labsize(*1.3)) xlab(1 "0" 4 "1" 8 "2" 12 "3" 16 "4" 20 "5", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
				
	* C5 
		tab c5 if q ==1
		twoway ///
			lpoly cma_q q if c5 ==1, bwidth(2) color("$green")   || /// 
			lpoly cma_q q if c5 ==2, bwidth(2) color("$blue") || /// 			
			lpoly cma_q q if c5 ==3, bwidth(2) color("$purple") || /// 
			lpoly cma_q q if c5 ==4, bwidth(2) color("$red") || /// 
			lpoly cma_q q if c5 ==5, bwidth(2) color(black) /// 
				scheme(cleanplots) xtitle("Time since baseline, years", size(*1.3)) ytitle("Mean CMA, %", size(*1.3))  ///
				name("c5", replace)  ysize(4) xsize(4.5) ///
				ylab(0(10)100, labsize(*1.3)) xlab(1 "0" 4 "1" 8 "2" 12 "3" 16 "4" 20 "5", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
				
	* C6 
		tab c6 if q ==1
		twoway ///
			lpoly cma_q q if c6 ==1, bwidth(2) color("$green")   || /// 
			lpoly cma_q q if c6 ==2, bwidth(2) color("$blue") || /// 			
			lpoly cma_q q if c6 ==3, bwidth(2) color("$purple") || /// 
			lpoly cma_q q if c6 ==4, bwidth(2) color("$red") || /// 
			lpoly cma_q q if c6 ==5, bwidth(2) color(pink) || /// 
			lpoly cma_q q if c6 ==6, bwidth(2) color(black) /// 
				scheme(cleanplots) xtitle("Time since baseline, years", size(*1.3)) ytitle("Mean CMA, %", size(*1.3))  ///
				name("c6", replace)  ysize(4) xsize(4.5) ///
				ylab(0(10)100, labsize(*1.3)) xlab(1 "0" 4 "1" 8 "2" 12 "3" 16 "4" 20 "5", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
				
	* C4
		recode c4 (3=4) (4=3)
		tab c4 if q ==.5
		twoway ///
			lpoly cma_q q if c4 ==1, bwidth(2) color("$green") lwidth(*1.8)  || /// 
			lpoly cma_q q if c4 ==2, bwidth(2) color("$blue")  lwidth(*1.8) || /// 			
			lpoly cma_q q if c4 ==3, bwidth(2) color("$purple") lwidth(*1.8) || /// 
			lpoly cma_q q if c4 ==4, bwidth(2) color("$red") lwidth(*1.8) /// 
				scheme(cleanplots) xtitle("Time since baseline, years", size(*1.3)) ytitle("Mean CMA, %", size(*1.3))  ///
				name("c4", replace)  xsize(5) ysize(4) ///
				ylab(0(10)100, labsize(*1.3)) xlab(0 "0" 4 "1" 8 "2" 12 "3" 16 "4" 20 "5", labsize(*1.3)) graphregion(margin(b-4)) ///
				legend(size(*1.5)) legend(label(1 "Continuous high adherence")) legend(label(2 "Decreasing adherence")) legend(label(3 "Increasing adherence")) legend(label(4 "Continuous non-adherence")) ///
				text(100 -2.9 "A", size(*1.75)) ///
				legend(position(6) row(4)) 
				
	* Multinominal logistic regression 
	
		* Data preparation 
			use patient c2-c6 using "$clean/CMAq_c", clear
			merge 1:m patient using "$clean/analyseCMAq", assert(match)
			keep if q ==1
			keep patient c2 c3 c4 c5 c6 sex initiator F0 F1 F2 F3 F4 F5 F9 age age_cat
			recode c4 (3=4) (4=3)
			lab define F9 0 "No mental disorder", modify
			lab var F9 "Mental health at baseline"
		
		* Loop over outcomes 
			foreach j in 1 2 3 4 {

			* Model 
				mlogit c4 ib2.age_cat##ib2.sex i.F9, base(1) rrr
				
				* Declining
					contrasts F9 age_cat sex, effect equation(2) rr
					postsave F9 age_cat sex, ciseparator("-") number(0) baselevels heading keep(var est varname label id) save("$temp/reg") varsuffix(2)  /// 
					estlab("aRR (95% CI)") baselabel("1.00") collab("Declining") sort(varname2 id2)

				* Increasing
					contrasts F9 age_cat sex, effect equation(3) rr
					postsave F9 age_cat sex, ciseparator("-") number(0) baselevels heading keep(var label est) merge("$temp/reg") varsuffix(3)  /// 
					estlab("aRR (95% CI)") baselabel("1.00") collab("Increasing") sort(varname2 id2)
					
				* Increasing
					contrasts F9 age_cat sex, effect equation(4) rr
					postsave F9 age_cat sex, ciseparator("-") number(0) baselevels heading keep(var label est) merge("$temp/reg") varsuffix(4)  /// 
					estlab("aRR (95% CI)") baselabel("1.00") collab("Non-adherent") sort(varname2 id2)
					
			* Export table to word 
				use label est* using "$temp/reg", clear 
				capture putdocx clear
				putdocx begin, font("Arial", 8) landscape
				putdocx paragraph, spacing(after, 0) 
				putdocx text ("Table S1: Risk ratios for factors associated with declining adherence, increasing adherence, or continuous non-adherence compared to continuous high adherence"), font("Arial", 9, black) bold
				putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
				putdocx table tbl1(., .), halign(right) font("Arial", 8)
				putdocx table tbl1(., 1), halign(left)
				putdocx table tbl1(1, .), halign(center) border(bottom, single) bold
				putdocx save "$tables/Table S1.docx", replace
				
			* Data preparation 
				use patient c2-c6 using "$clean/CMAq_c", clear
				merge 1:m patient using "$clean/analyseCMAq", assert(match)
				keep if q ==1
				keep patient c2 c3 c4 c5 c6 sex initiator F0 F1 F2 F3 F4 F5 F9 age age_cat
				recode c4 (3=4) (4=3)

			* Model 
				mlogit c4 ib2.age_cat##ib2.sex i.F9, base(1) rrr
			
			* Predict margins 
				margins age_cat#sex, at(F9==0) at(F9==1) predict(outcome(`j'))
			
			* Estimates to dataset 	
				matrix list r(table)
				matrix t = r(table)'
				preserve 
				clear
				svmat2 t, names(col) rnames(name)
					
			* MHD 
				gen at = substr(name, 1, 1)
				gen MHD = at =="2"
				drop at
					
			* age_cat 
				capture drop age_cat
				gen age_cat = ""
				replace age_cat = regexs(1) if regexm(name,"([0-9]+)(.age_cat)")
				replace age_cat = regexs(1) if regexm(name,"([0-9]+)(bn.age_cat)")
				destring age_cat, replace
				assert age_cat !=.
					
			* Sex 
				capture drop sex
				gen sex = ""
				replace sex = regexs(1) if regexm(name,"([0-9]+)(.sex)")
				replace sex = regexs(1) if regexm(name,"([0-9]+)(bn.sex)")
				destring sex, replace
				assert sex !=.
				
			* Outcome 
				gen outcome = `j'
				
			* Save 
				save "$temp/outcome`j'", replace
				restore
		}
			
	* Append 
		use "$temp/outcome1", clear
		append using "$temp/outcome2"
		append using "$temp/outcome3"
		append using "$temp/outcome4"
		tab outcome, mi

	* Labels 
		lab define age_cat 0 "15-19" 1 "20-24" 2 "25-34" 3 "34-44" 4 "45-54" 5 "55-64" 6 "65+", replace
		lab val age_cat age_cat 
		lab define sex 1 "Men" 2 "Women", replace
		lab val sex sex
			
	* Clean 
		keep b ll ul name MHD age_cat sex outcome
		order outcome name MHD age_cat sex b ll ul
		sort outcome name
		
	* Assert sum of outcomes is 100% 
		preserve 
		collapse (sum)b, by(name)
		assert float(b) ==1
		restore
		
	* Reshape 
		reshape wide b ll ul, i(MHD age_cat sex) j(outcome)
			
	* Top borders  		
		gen top0 = 0 
		gen top1 = b1
		gen top2 = b1 + b2 
		gen top3 = b1 + b2 + b3 
		gen top4 = b1 + b2 + b3 + b4

	* Plot 
		forvalues j = 1/2 {
		
		* Select sex 
			preserve 
			keep if sex ==`j'
		
		* X 
			sort age_cat MHD 
			gen x = _n, before(MHD)
			replace x = x + age_cat
			
		* Bounds 
		   foreach b in 2 3 4 {
				gen l`b' = top`b' - (ul`b'-ll`b')/2  
				gen u`b' = top`b' + (ul`b'-ll`b')/2
			}
		
		* xL and xR
			capture drop xL xR
			gen xL = x - .04
			gen xR = x + .04
			
		* Title 
			if "`j'" =="1" {
				local ti = "Men"
				local L = "B"
			}
			else if "`j'" =="2" {
				local ti = "Women"
				local L = "C"
			}
				
		* Plot 
			twoway ///
				rbar top0 top1 x if MHD ==0, color("$green")  fintensity(inten80) lcolor(white) || /// 
				rbar top0 top1 x if MHD ==1, color("$green")  fintensity(inten30) lcolor(white) ||  /// 		
				rbar top1 top2 x if MHD ==0, color("$blue")   fintensity(inten80) lcolor(white) || /// 
				rbar top1 top2 x if MHD ==1, color("$blue")   fintensity(inten30) lcolor(white) || /// 	
				rbar top2 top3 x if MHD ==0, color("$purple") fintensity(inten80) lcolor(white) || /// 
				rbar top2 top3 x if MHD ==1, color("$purple") fintensity(inten30) lcolor(white) ||  /// 		
				rbar top3 top4 x if MHD ==0, color("$red")    fintensity(inten80) lcolor(white) || /// 
				rbar top3 top4 x if MHD ==1, color("$red")    fintensity(inten30) lcolor(white) /// 	
				xlab(0.5 " " 1.5 "15-19" 4.5 "20-24" 7.5 "25-34" 10.5 "34-44" 13.5 "45-54" 16.5 "55-64" 19.5 "65+", angle(45) labsize(*1.3)) ///
				ylab(, labsize(*1.3)) ///
				xtitle("Age, years", size(*1.3)) scheme(cleanplots) ytitle("Probability", size(*1.3)) title("`ti'", size(*1.3)) xsize(5) ysize(4) name(sex_`j', replace) text(1 -2 "`L'", size(*1.75)) ///
				graphregion(margin(b-0.5 t-1 l-1 r-1)) ///
				legend(label(1 "Continuously high adherence")) legend(label(3 "Decreasing adherence")) legend(label(5 "Increasing adherence")) legend(label(7 "Continuously non-adherent")) ///
				legend(position(6) row(4)) legend(off)
						
		* Restore 
			restore 
				
		}
		
				
		* Combine plots & export 
			graph combine c4 sex_1 sex_2, ///
			col(1) ysize(12) xsize(5) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figure3, replace)	
			graph export "$figures/Figure 3.tif", as(tif) name(figure3) replace  width(600)		
			
			
* Table with predicted probabilities and CIs
	foreach s in 1 2 {
		foreach m in 0 1 {
		
		* Data
			use "$temp/outcome1", clear
			append using "$temp/outcome2"
			append using "$temp/outcome3"
			append using "$temp/outcome4"
			tab outcome, mi

		* Labels 
			lab define age_cat 0 "15-19" 1 "20-24" 2 "25-34" 3 "34-44" 4 "45-54" 5 "55-64" 6 "65+", replace
			lab val age_cat age_cat 
			lab define sex 1 "Men" 2 "Women", replace
			lab val sex sex
			
		* Clean 
			keep b ll ul MHD age_cat sex outcome
			order sex age_cat MHD outcome b ll ul
			gsort sex age_cat -outcome
			keep if MHD == `m' & sex ==`s'
			
			foreach var in b ll ul {
				replace `var' = `var' * 100
				format `var' %3.1fc
			}
		
		* Estimate
			gen est = string(b, "%3.1fc") + "% (" + string(ll, "%3.1fc") + "-" + string(ul, "%3.1fc") + ")"
			drop b ll ul
			
		* Outcome	
			lab define outcome 1 "Adherent" 2 "Declining" 3 "Increasing" 4 "Non-adherent", replace 
			lab val outcome outcome
			
		* Reshpae 
			reshape wide est, i(outcome) j(age_cat)
			
		* Sort 
			gsort -outcome
			
		* Save 
			save "$temp/mhd`m'sex`s'", replace
			 export excel using "$temp/mhd`m'sex`s'", sheetreplace firstrow(variables)
			
			
		}
	}
	