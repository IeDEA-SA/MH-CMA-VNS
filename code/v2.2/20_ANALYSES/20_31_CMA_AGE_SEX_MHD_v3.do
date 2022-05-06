**** CMA by age, sex and mental health status 

	* VF by sex and age 
		foreach y in 2 {
		
			* Data
				use "$clean/analyseCMAy", clear
				gunique pat
				*merge m:1 patient using "$temp/NVL_patients", keep(match)
		
			* Model 
				glm cma_y i.F9 ib3.age_cat ib1.sex i.y /// exposures and time 
							i.F9#ib3.age_cat i.F9#ib1.sex /// interaction terms for mental health diagnoses by time age and sex 
							ib3.age_cat#ib1.sex, /// 
							vce(cluster patient) family(gamma) link(log)
				margins age_cat#sex, at(F9=0 y=2) at(F9=1 y=2)  
					
			* Estimates to dataset 	
				matrix list r(table)
				matrix t = r(table)'
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
							
			* Plot - Men 
				capture drop xL*
				capture drop xR*
				gen xL = age_cat-0.075
				gen xLL = age_cat-0.15
				gen xR = age_cat+0.075
				gen xRR = age_cat+0.15
				twoway rcap ll ul xL if MHD ==0 & sex ==1, color("$blue")  ///
					|| rcap ll ul xR if MHD ==1 & sex ==1, color("$red") ///
					|| scatter b xL if MHD ==0 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter b xR if MHD ==1 & sex ==1, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("CMA, %", size(*1.3))  ///
					title("Men", size(*1.3)) name("Men_`y'", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					ylab(60(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))
					
			* Plot - Women
				twoway rcap ll ul xL if MHD ==0 & sex ==2, color("$blue")  ///
					|| rcap ll ul xR if MHD ==1 & sex ==2, color("$red") ///
					|| scatter b xL if MHD ==0 & sex ==2, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter b xR if MHD ==1 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("CMA, %", size(*1.3))  ///
					title("Women", size(*1.3)) name("Women_`y'", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					legend(off) ///
					ylab(60(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))
					
		}
			  
		* Combine plots & export 
			graph combine Men_2 Women_2, ///
			col(1) xsize(2) ysize(4) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figure1, replace)	
			graph export "$figures/Figure 1.tif", as(tif) name(figure1) replace  width(600)
				
		* Figure 2: 
			capture putdocx clear
			putdocx begin, font("Arial", 8)
			putdocx paragraph, spacing(after, 8 pt)
			putdocx text ("Figure 1. Cumulative medication availability (CMA) in the second years after baseline by sex, age and mental health status"), font("Arial", 9, black) bold 
			putdocx paragraph, spacing(after, 0)
			putdocx text ("Error bars represent 95% confidence intervals for means and proportions. "), font("Arial", 9, black)  
			putdocx image "$figures/Figure 1.tif"
			putdocx pagebreak
			putdocx save "$figures/Figure 1.docx", replace
			
			
		* Plot - No MHD  
				capture drop xL*
				capture drop xR*
				gen xL = age_cat-0.075
				gen xLL = age_cat-0.15
				gen xR = age_cat+0.075
				gen xRR = age_cat+0.15
				twoway rcap ll ul xL if MHD ==0 & sex ==1, color("$blue")  ///
					|| rcap ll ul xR if MHD ==0 & sex ==2, color("$red") ///
					|| scatter b xL if MHD ==0 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter b xR if MHD ==0 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("CMA, %", size(*1.3))  ///
					title("No mental illness", size(*1.3)) name("No_MHD", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "Men")) legend(label(4 "Women")) legend(size(*1)) ///
					ylab(60(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))
					
			* Plot - MHD 
				twoway rcap ll ul xL if MHD ==1 & sex ==1, color("$blue")  ///
					|| rcap ll ul xR if MHD ==1 & sex ==2, color("$red") ///
					|| scatter b xL if MHD ==1 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter b xR if MHD ==1 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("CMA, %", size(*1.3))  ///
					title("Mental illness", size(*1.3)) name("MHD", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "Women")) legend(label(4 "Mental illness")) legend(size(*1)) legend(off) ///
					ylab(60(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))
			
			* Combine plots & export 
			graph combine No_MHD MHD, ///
			col(1) xsize(2) ysize(4) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figureS3, replace)	
			graph export "$figures/Figure S3.tif", as(tif) name(figureS3) replace  width(600)
