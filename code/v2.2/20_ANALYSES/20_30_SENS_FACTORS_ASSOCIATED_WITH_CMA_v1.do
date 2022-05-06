		
*** FACTORS ASSOCIATED WITH CMA < 80%: Sensitivity analysis with other outcome definitions 

* Loop over definitons 
	foreach d in 90 180 365 {
		
	* Dataset 
		use "$clean/analyseCMAy", clear
		*merge m:1 patient using "$temp/NVL_patients", keep(match)
		
	* Adherence over 5 years  
		drop if y >5
		
	* N 
		gunique pat
		
	* Non-adherence 
		foreach j in 70 80 90 {
			gen byte na_y`j' =  cma < `j'
			tabstat cma, stat(min max) by(na_y`j')
		}
						
	* List 
		listif patient y na_y80 age_cat sex F9, id(pat) n(30) seed(3) sort(patient y) sepby(pat) nolab
		
	* Unadjusted risk ratio
		
		* Mental disorders 
			
			* First row 
				lab var F0_`d' "Mental health diagnoses"
				lab define F0 0 "No mental health diagnoses", add
				mepoisson na_y80 i.F0_`d'##i.y || patient: , vce(robust) irr 
				contrast F0_`d', effect irr
				postsave F0_`d', number(0) baselevels heading keep(var est varname label level id number) save("$temp/adh") varsuffix(0) ///
				estlab("Unadjusted risk ratio (95% CI)") baselabel("1.00")	
			
			* Other rows 
				foreach j in 1 2 3 4 5 9 {
					mepoisson na_y80 i.F`j'_`d'##i.y || patient: , vce(robust) irr 
					contrast F`j'_`d', effect irr
					postsave F`j'_`d', number(`j') baselevels keep(var est varname label level id number) dropcoeff(0.F`j') append("$temp/adh") sort(number0 id0) varsuffix(0) baselabel("1.00")	
				}
							
		* Age 
			mepoisson na_y80 ib6.age_cat|| patient: , vce(robust) irr 
			contrast age_cat, effect irr
			postsave age_cat, number(10) baselevels keep(var est varname label level id number) append("$temp/adh") sort(number0 id0) varsuffix(0)	heading	baselabel("1.00")			
						
		* Sex  
			mepoisson na_y80 ib2.sex|| patient: , vce(robust) irr 
			contrast sex, effect irr
			postsave sex, number(11) baselevels keep(var est varname label level id number) append("$temp/adh") sort(number0 id0) varsuffix(0)	heading baselabel("1.00")	
		
	* Adjusted risk ratio 
	
		* Any mental disorders
				
			* Model 
				mepoisson na_y80 i.F9_`d' ib6.age_cat ib2.sex i.y /// exposures and time 
				i.F9_`d'#i.y i.F9_`d'#ib6.age_cat i.F9_`d'#ib2.sex /// interaction terms for mental health diagnoses by time age and sex 
				ib6.age_cat#ib2.sex|| patient: , vce(robust) irr  // sex#age 
					
			* Effect table 
				contrast F9_`d' age_cat sex, effect irr
				postsave F9_`d' age_cat sex, number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(1)  estlab("Adjusted risk ratio (95% CI)") 	sort(number0 id0) ///
				dropcoefficient(0.F9 h.F9) baselabel("1.00")	
			
		* Individual disorders 
			
			* Model 
				mepoisson na_y80 i.F0_`d' i.F1_`d' i.F2_`d' i.F3_`d' i.F4_`d' i.F5_`d' ib6.age_cat ib2.sex i.y /// exposures and time 
				i.F1#i.y  /// F1: interaction terms for mental health diagnoses by time
				i.F2#i.y  /// F2: interaction terms for mental health diagnoses by time 
				i.F3#i.y  /// F3: interaction terms for mental health diagnoses by time 
				i.F4#i.y /// F4: interaction terms for mental health diagnoses by time 
				i.F5#i.y  /// F5: interaction terms for mental health diagnoses by time 
				ib6.age_cat#ib2.sex|| patient: , vce(robust) irr  // sex#age 
				
			* Effect table 
				contrasts F0_`d' F1_`d' F2_`d' F3_`d' F4_`d' F5_`d' age_cat sex, effect irr
				postsave F0_`d' F1_`d' F2_`d' F3_`d' F4_`d' F5_`d' age_cat sex,  number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(3)  estlab("Adjusted risk ratio (95% CI)") 	///
				sort(number0 id0) clean dropcoefficient(h.F[0-5] 0.F[1-5]) baselabel("1.00")	
			
	* Export table 
			use var label est* using "$temp/adh", clear 
			list, sep(`=_N')
			replace est1 = "1.00" if var =="0.F0"
			drop var
			capture putdocx clear
			putdocx begin, font("Arial", 8) 
			putdocx paragraph, spacing(after, 0) 
			putdocx text ("Table 2: Unadjusted and adjusted risk ratios for non-adherence (CMA <80%)"), font("Arial", 9, black) bold
			putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
			putdocx table tbl1(., .), halign(right) font("Arial", 8)
			putdocx table tbl1(., 1), halign(left)
			putdocx table tbl1(1, .), halign(center) border(bottom, single) bold
			putdocx save "$tables/Table 2_`d'.docx", replace		
			
}
		
	
