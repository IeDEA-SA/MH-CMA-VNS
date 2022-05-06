		
*** FACTORS ASSOCIATED WITH CMA < 80%
		
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
				lab var F0 "Mental disorder"
				lab define F0 0 "No mental disorder", add
				mepoisson na_y80 i.F0 || patient: , vce(robust) irr 
				contrast F0, effect irr
				postsave F0, number(0) baselevels heading keep(var est varname label level id number) save("$temp/adh") varsuffix(0) ///
				estlab("Unadjusted risk ratio (95% CI)") baselabel("1.00")	
			
			* Other rows 
				foreach j in 1 2 3 4 5 9 {
					mepoisson na_y80 i.F`j' || patient: , vce(robust) irr 
					contrast F`j', effect irr
					postsave F`j', number(`j') baselevels keep(var est varname label level id number) dropcoeff(0.F`j') append("$temp/adh") sort(number0 id0) varsuffix(0) baselabel("1.00")	
				}
			
		* Age 
			mepoisson na_y80 ib6.age_cat || patient: , vce(robust) irr 
			contrast age_cat, effect irr
			postsave age_cat, number(10) baselevels keep(var est varname label level id number) append("$temp/adh") sort(number0 id0) varsuffix(0)	heading	baselabel("1.00")			
						
		* Sex  
			mepoisson na_y80 ib2.sex || patient: , vce(robust) irr 
			contrast sex, effect irr
			postsave sex, number(11) baselevels keep(var est varname label level id number) append("$temp/adh") sort(number0 id0) varsuffix(0)	heading baselabel("1.00")	
		
	* Adjusted risk ratio 
	
		* Any mental disorders	
			foreach j in 9 0 1 2 3 4 5  {
				
			* Model 
				mepoisson na_y80 i.F`j' i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr
					
			* Effect table 
				contrast F`j' age_cat sex, effect irr
				postsave F`j' age_cat sex, number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(1) estlab("Adjusted risk ratio (95% CI)") sort(number0 id0) ///
				dropcoefficient(0.F`j' h.F`j') baselabel("1.00") clean	
				
			}
			
		* Individual disorders 
			
			* Model 
				mepoisson na_y80 i.F0 i.F1 i.F2 i.F3 i.F4 i.F5 i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr  
				
			* Effect table 
				contrasts F0 F1 F2 F3 F4 F5 age_cat sex, effect irr
				postsave F0 F1 F2 F3 F4 F5 age_cat sex,  number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(2)  estlab("Adjusted risk ratio (95% CI)") 	///
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
			putdocx save "$tables/Table 2.docx", replace		
		
	
*** FACTORS ASSOCIATED WITH CMA < 70%
		
	* Dataset 
		use "$clean/analyseCMAy", clear
		lab var F0 "Mental health diagnosis"
		lab define F0 0 "No mental health diagnosis", add
		
	* Adherence over 5 years  
		drop if y >5
	
	* Non-adherence 
		foreach j in 70 80 90 {
			gen byte na_y`j' =  cma < `j'
			tabstat cma, stat(min max) by(na_y`j')
		}
		
	* CMA <80%	
		foreach j in 0 1 2 3 4 5 9  {
				
		* Model 
			qui mepoisson na_y80 i.F`j' i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr
					
		* Effect table 
			qui contrast F`j', effect irr
			if `j' == 0 postsave F`j', number(0) baselevels heading keep(var est varname label level id number) save("$temp/adh") varsuffix(0) estlab("CMA <80% aRR (95% CI)") sort(id0 varname0) dropcoef(0.F`j' h.F[1-9]) baselab("1.00") clean
			else postsave F`j', number(0) baselevels heading keep(var est varname label level id number) append("$temp/adh") varsuffix(0) sort(id0 varname0) dropcoefficient(0.F`j' h.F[1-9]) baselabel("1.00") clean
				
		}
		
	* CMA <70%	
		foreach j in 0 1 2 3 4 5 9  {
				
		* Model 
			qui mepoisson na_y70 i.F`j' i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr
					
		* Effect table 
			qui contrast F`j', effect irr
			if `j' == 0 postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(1) estlab("CMA <70% aRR (95% CI)") sort(id0 varname0) dropcoef(0.F`j' h.F[1-9]) baselab("1.00") clean
			else postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(1) sort(id0 varname0) dropcoefficient(0.F`j' h.F[1-9]) baselabel("1.00") clean
				
		}	
		
	* CMA <90%	
		foreach j in 0 1 2 3 4 5 9  {
				
		* Model 
			qui mepoisson na_y90 i.F`j' i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr
					
		* Effect table 
			qui contrast F`j', effect irr
			if `j' == 0 postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(2) estlab("CMA <90% aRR (95% CI)") sort(id0 varname0) dropcoef(0.F`j' h.F[1-9]) baselab("1.00") clean
			else postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(2) sort(id0 varname0) dropcoefficient(0.F`j' h.F[1-9]) baselabel("1.00") clean
				
		}	
		
	* Dataset 
		use "C:/Data/IeDEA/Adh/v3/clean/analyseCMAy", clear
		lab var F0 "Mental health diagnosis"
		lab define F0 0 "No mental health diagnosis", add
		
	* Adherence over 5 years  
		drop if y >5
	
	* Non-adherence 
		foreach j in 70 80 90 {
			gen byte na_y`j' =  cma < `j'
			tabstat cma, stat(min max) by(na_y`j')
		}
		
	* CMA <80%	
		foreach j in 0 1 2 3 4 5 9  {
				
		* Model 
			qui mepoisson na_y80 i.F`j' i.y ib6.age_cat ib2.sex ib6.age_cat#ib2.sex || patient: , vce(robust) irr
					
		* Effect table 
			qui contrast F`j', effect irr
			if `j' == 0 postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(3) estlab("Repeated diag, CMA <80% aRR (95% CI)") sort(id0 varname0) dropcoef(0.F`j' h.F[1-9]) baselab("1.00") clean
			else postsave F`j', number(0) baselevels heading keep(var est varname label level id number) merge("$temp/adh") varsuffix(3) sort(id0 varname0) dropcoefficient(0.F`j' h.F[1-9]) baselabel("1.00") clean
				
		}	
		
			
	* Export table 
			use var label est* using "$temp/adh", clear 
			list, sep(`=_N')
			replace est1 = "1.00" if var =="0.F0"
			drop var
			capture putdocx clear
			putdocx begin, font("Arial", 8) 
			putdocx paragraph, spacing(after, 0) 
			putdocx text ("Table S4: Unadjusted and adjusted risk ratios for non-adherence (CMA <70%)"), font("Arial", 9, black) bold
			putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
			putdocx table tbl1(., .), halign(right) font("Arial", 8)
			putdocx table tbl1(., 1), halign(left)
			putdocx table tbl1(1, .), halign(center) border(bottom, single) bold
			putdocx save "$tables/Table S4.docx", replace		
			
