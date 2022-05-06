**** CMA by age, sex and mental health status 

* VL 400: overall 
	
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
	
	* VF by sex and age 
		
			* Model 
				mepoisson vf400 i.F9 i.YOA || patient: , vce(robust) irr  	
				margins, at(F9=0 YOA=5) at(F9=1 YOA=5)  
					
			* Estimates to dataset 	
				matrix list r(table)
				matrix t = r(table)'
				clear
				svmat2 t, names(col) rnames(name)
				
			* MHD 
				gen at = substr(name, 1, 1)
				gen MHD = at =="2"
				drop at
							
			* VLS	
				gen vls = (1-b)*100
				gen vls_ll = (1-ul)*100
				gen vls_ul = (1-ll)*100
				foreach var in b ll ul vls vls_ll vls_ul {
					assert inrange(`var', 0, 100)
					format `var' %3.0fc
				}
				
			* List 
				list MHD vls*

* VL 400 
	
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
	
	* VF by sex and age 
		
			* Model 
				mepoisson vf400 i.F9 i.YOA i.F9#i.ib3.age_cat i.F9#ib1.sex ib3.age_cat##ib1.sex || patient: , vce(robust) irr  	
				margins age_cat#sex, at(F9=0 YOA=2) at(F9=1 YOA=2)  
					
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
				
			* VLS	
				gen vls = (1-b)*100
				gen vls_ll = (1-ul)*100
				gen vls_ul = (1-ll)*100
				foreach var in b ll ul {
					assert inrange(`var', 0, 100)
					*replace `var' = 0 if `var' < 0 
					*replace `var' = 100 if `var' > 100 & `var' !=.
				}
				
			* Save 
				save "$temp/vf400_age_sex_mh", replace
				use "$temp/vf400_age_sex_mh", clear
			
			* Plot - Men 
				capture drop xL*
				capture drop xR*
				gen xL = age_cat-0.075
				gen xLL = age_cat-0.15
				gen xR = age_cat+0.075
				gen xRR = age_cat+0.15
				twoway rcap vls_ll vls_ul xL if MHD ==0 & sex ==1, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==1 & sex ==1, color("$red") ///
					|| scatter vls xL if MHD ==0 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==1 & sex ==1, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("Men", size(*1.3)) name("Men", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))  // text(105 -1.15 "A", size(*1.8))
					
			* Plot - Women
				twoway rcap vls_ll vls_ul xL if MHD ==0 & sex ==2, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==1 & sex ==2, color("$red") ///
					|| scatter vls xL if MHD ==0 & sex ==2, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==1 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("Women", size(*1.3)) name("Women", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
			  
			* Combine plots & export 
				graph combine Men Women, ///
				col(1) xsize(2) ysize(4) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figure2, replace)	// graphregion(lcolor(gs1)) graphregion(lwidth(medthick)) 
				graph export "$figures/Figure 2.tif", as(tif) name(figure2) replace  width(600)
				
		* Figure S4: 
		
			* Plot - No MHD  
				capture drop xL*
				capture drop xR*
				gen xL = age_cat-0.075
				gen xLL = age_cat-0.15
				gen xR = age_cat+0.075
				gen xRR = age_cat+0.15
				twoway rcap vls_ll vls_ul xL if MHD ==0 & sex ==1, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==0 & sex ==2, color("$red") ///
					|| scatter vls xL if MHD ==0 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==0 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("No mental health diagnosis", size(*1.3)) name("No_MHD", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "Men")) legend(label(4 "Women")) legend(size(*1)) ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "34-44" 4 "44-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2)) // text(105 -1.15 "B", size(*1.8))
					
			* Plot - MHD
				twoway rcap vls_ll vls_ul xL if MHD ==1 & sex ==1, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==1 & sex ==2, color("$red") ///
					|| scatter vls xL if MHD ==1 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==1 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("Mental health diagnosis", size(*1.3)) name("MHD", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "Men")) legend(label(4 "Women")) legend(size(*1))  ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "34-44" 4 "44-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
			  
			* Combine plots & export 
				graph combine No_MHD MHD, ///
				col(1) xsize(2) ysize(4) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figureS4, replace)	// graphregion(lcolor(gs1)) graphregion(lwidth(medthick))
				graph export "$figures/Figure S4.tif", as(tif) name(figureS4) replace  width(600)
				
* VL 1000
	
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
	
	* VF by sex and age 
		
			* Model 
				mepoisson vf1000 i.F9 i.YOA i.F9#i.ib3.age_cat i.F9#ib1.sex ib3.age_cat##ib1.sex || patient: , vce(robust) irr  	
				margins age_cat#sex, at(F9=0 YOA=2) at(F9=1 YOA=2)  
					
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
				
			* VLS	
				gen vls = (1-b)*100
				gen vls_ll = (1-ul)*100
				gen vls_ul = (1-ll)*100
				foreach var in b ll ul {
					assert inrange(`var', 0, 100)
					*replace `var' = 0 if `var' < 0 
					*replace `var' = 100 if `var' > 100 & `var' !=.
				}
				
			* Save 
				save "$temp/vf1000_age_sex_mh", replace
				use "$temp/vf1000_age_sex_mh", clear
			
			* Plot - Men 
				capture drop xL*
				capture drop xR*
				gen xL = age_cat-0.075
				gen xLL = age_cat-0.15
				gen xR = age_cat+0.075
				gen xRR = age_cat+0.15
				twoway rcap vls_ll vls_ul xL if MHD ==0 & sex ==1, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==1 & sex ==1, color("$red") ///
					|| scatter vls xL if MHD ==0 & sex ==1, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==1 & sex ==1, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("Men", size(*1.3)) name("Men", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2))  // text(105 -1.15 "A", size(*1.8))
					
			* Plot - Women
				twoway rcap vls_ll vls_ul xL if MHD ==0 & sex ==2, color("$blue")  ///
					|| rcap vls_ll vls_ul xR if MHD ==1 & sex ==2, color("$red") ///
					|| scatter vls xL if MHD ==0 & sex ==2, connect(direct) color("$blue")  msymbol(o) /// 
					|| scatter vls xR if MHD ==1 & sex ==2, connect(direct) color("$red") msymbol(o)  /// 
					scheme(cleanplots) xtitle("Age, years", size(*1.3)) ytitle("Viral suppression, %", size(*1.3))  ///
					title("Women", size(*1.3)) name("Women", replace)  ///
					ysize(4) xsize(4.5) legend(ring(0) position(11) bmargin(medium)) legend(size(*1.3)) legend(order(3 4)) legend(label(3 "No mental health diagnosis")) legend(label(4 "Mental health diagnosis")) legend(size(*1)) ///
					ylab(40(10)100, labsize(*1.3)) xlab(0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", labsize(*1.3)) graphregion(margin(b-2)) legend(off)
			  
			* Combine plots & export 
				graph combine Men Women, ///
				col(1) xsize(2) ysize(4) graphregion(color(white)) iscale(*1.0) graphregion(margin(b-1.5 t-1 l-3 r-1))	name(figure2, replace)	// graphregion(lcolor(gs1)) graphregion(lwidth(medthick)) 
				graph export "$figures/Figure 2_1000.tif", as(tif) name(figure2) replace  width(600)
				
* VL 100
	
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
			
		* VL
			rename hiv_rna lab_v
			foreach t in 100  {
				gen vf`t' = 0
				replace vf`t' = 1 if lab_v >= `t' & qualifier !="<"
				sum lab_v if vf`t' ==1
				tab qualifier if vf`t' ==1
			}
	
	* VF by sex and age 
		
			* Model 
				mepoisson vf100 i.F9 i.YOA i.F9#i.ib3.age_cat i.F9#ib1.sex ib3.age_cat##ib1.sex || patient: , vce(robust) irr  	
				margins age_cat#sex, at(F9=0 YOA=2) at(F9=1 YOA=2)  
					
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
				
			* VLS	
				gen vls = (1-b)*100
				gen vls_ll = (1-ul)*100
				gen vls_ul = (1-ll)*100
				foreach var in b ll ul {
					assert inrange(`var', 0, 100)
					*replace `var' = 0 if `var' < 0 
					*replace `var' = 100 if `var' > 100 & `var' !=.
				}
				
			* Save 
				save "$temp/vf100_age_sex_mh", replace
				use "$temp/vf100_age_sex_mh", clear
				
				
				
* Table with suppression rates and CIs
		
		* Data
			use "$temp/vf400_age_sex_mh", clear
			gen VL=400
			append using "$temp/vf100_age_sex_mh"
			replace VL = 100 if VL ==.
			append using "$temp/vf1000_age_sex_mh"
			replace VL = 1000 if VL ==.
		
		* Labels 
			lab define age_cat 0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", replace
			lab val age_cat age_cat 
			lab define sex 1 "Men" 2 "Women", replace
			lab val sex sex
			
		* Clean 
			keep b ll ul MHD age_cat sex VL
			order sex age_cat MHD b ll ul
			gsort sex age_cat 
			
			foreach var in b ll ul {
				replace `var' = (1 - `var') * 100
				format `var' %3.1fc
			}
		
		* Estimate
			gen est = string(b, "%3.1fc") + "% (" + string(ul, "%3.1fc") + "-" + string(ll, "%3.1fc") + ")"
			drop b ll ul
			
		* Reshpae 
			reshape wide est, i(sex age_cat VL) j(MHD)
			rename est0 est_MHD0_VL
			rename est1 est_MHD1_VL
			reshape wide est_MHD0_VL est_MHD1_VL, i(sex age_cat) j(VL)
			
		* Save 
			export excel using "$temp/VLS", sheetreplace firstrow(variables)
			
		
	