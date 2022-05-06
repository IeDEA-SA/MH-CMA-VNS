		
*** FACTORS ASSOCIATED WITH NVL: 400 copies/mL
   *https://stats.oarc.ucla.edu/stata/examples/mlm-ma-hox/multilevel-analysis-techniques-and-applications-by-joop-hoxchapter-5-analyzing-longitudinal-data-2/
		
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
		preserve 
		bysort patient: keep if _n ==1
		keep patient 
		save "$temp/NVL_patients", replace
		restore
		
	* Tab 
		tab vf400 F9 if YOA ==1, col
		tab vf1000 F9, col
		
	*N 
		gunique pat // 28,785
			
		* Univariable analysis 
			* MH 
				lab var F0 "Mental health diagnosis"
				lab define F0 0 "No mental health diagnosis", add
				mepoisson vf400 i.F0 || patient: , vce(robust) irr 
				contrasts F0, effect irr
				postsave F0, ciseparator("-") number(0) baselevels heading keep(var est varname label level id number) save("$temp/vf400") varsuffix(0)  estlab("RR (95% CI)") 	baselabel("1.00")
				foreach j in 1 2 3 4 5 9 {
					mepoisson vf400 i.F`j' || patient: , vce(robust) irr 
					qui contrasts F`j', effect irr
					postsave F`j', ciseparator("-") number(`j') baselevels keep(var est varname label level id number) append("$temp/vf400") varsuffix(0)  dropcoefficient(0.F`j')
				}
			* Age 
				mepoisson vf400 ib2.age_cat || patient: , vce(robust) irr 
				contrasts age_cat, effect irr
				postsave age_cat, ciseparator("-") number(10) baselevels keep(var est varname label level id number) append("$temp/vf400") varsuffix(0) heading baselabel("1.00")
			* Sex 
				qui mepoisson vf400 ib2.sex || patient: , vce(robust) irr 
				contrasts sex, effect irr
				postsave sex, ciseparator("-") number(11) baselevels keep(var est varname label level id number) append("$temp/vf400") varsuffix(0) heading baselabel("1.00")
			* CMA
				qui mepoisson vf400 i.CMA180_cat || patient: , vce(robust) irr 
				contrasts CMA180_cat, effect irr
				postsave CMA180_cat, ciseparator("-") number(12) baselevels keep(var est varname label level id number) append("$temp/vf400") varsuffix(0) heading baselabel("1.00") 
				
		* Multivariable analysis: adjusted for age sex yoa and MH 
			foreach j in 9 0 1 2 3 4 5 {
				mepoisson vf400 i.F`j' i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
				contrasts F`j' age_cat sex, effect irr
				postsave F`j' age_cat sex CMA180_cat, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf400") varsuffix(1) heading baselabel("1.00") sort(number0 id0) estlab("aRR (95% CI)") ///
				dropcoefficient(h.F`j' 0.F`j') clean
			}
			
		* Multivariable analysis: adjusted for age sex yoa MH and CMA
			foreach j in 9 0 1 2 3 4 5 {
				mepoisson vf400 i.F`j' i.YOA ib2.age_cat##ib2.sex i.CMA180_cat || patient: , vce(robust) irr  
				contrasts F`j' age_cat sex CMA180_cat, effect irr
				postsave F`j' age_cat sex CMA180_cat, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf400") varsuffix(2) heading baselabel("1.00") sort(number0 id0) estlab("aRR (95% CI)") ///
				dropcoefficient(h.F`j' 0.F`j') clean
			}
			
		* Multivariable analysis: adjusted for age sex yoa and MH 
			qui mepoisson vf400 i.F0 i.F1 i.F2 i.F3 i.F4 i.F5 i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
			qui contrasts F0 F1 F2 F3 F4 F5 age_cat sex, effect irr
			postsave F0 F1 F2 F3 F4 F5 age_cat sex, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf400") varsuffix(3) heading baselabel("1.00") sort(number0 id0) estlab("aRR (95% CI)") ///
			dropcoefficient(h.F[0-5] 0.F[0-5]) clean
			
		* Multivariable analysis: adjusted for age sex yoa and MH 
			mepoisson vf400 i.F0 i.F1 i.F2 i.F3 i.F4 i.F5 i.YOA ib2.age_cat##ib2.sex i.CMA180_cat || patient: , vce(robust) irr  
			contrasts F0 F1 F2 F3 F4 F5 age_cat sex CMA180_cat, effect irr
			postsave F0 F1 F2 F3 F4 F5 age_cat sex CMA180_cat, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf400") varsuffix(4) heading baselabel("1.00") sort(number0 id0) estlab("aRR (95% CI)") ///
			dropcoefficient(h.F[0-5] 0.F[0-5]) clean
														
		* Export table 
			use label est* var using "$temp/vf400", clear 
			replace est1 = "1.00" if var =="0.F0"
			replace est2 = "1.00" if var =="0.F0"
			replace est3 = "1.00" if var =="0.F0"
			replace est4 = "1.00" if var =="0.F0"
			drop var
			capture putdocx clear
			putdocx begin, font("Arial", 8) landscape
			putdocx paragraph, spacing(after, 0) 
			putdocx text ("Table 3: Unadjusted and adjusted odds ratios for associations between mental health status and non-suppressed viral load (viral load ≥400 copies/mL)"), font("Arial", 9, black) bold
			putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
			putdocx table tbl1(., .), halign(right) font("Arial", 8)
			putdocx table tbl1(., 1), halign(left)
			putdocx table tbl1(1, .), halign(center) border(bottom, single) bold
			putdocx save "$tables/Table 3.docx", replace
					
*** FACTORS ASSOCIATED WITH NVL: 200 and 1000 copies/mL
   *https://stats.oarc.ucla.edu/stata/examples/mlm-ma-hox/multilevel-analysis-techniques-and-applications-by-joop-hoxchapter-5-analyzing-longitudinal-data-2/
		
	* Dataset 
		use if CMA180_cat !=. using "$clean/analyseNVL", clear
		lab var F0 "Mental health diagnosis"
		lab define F0 0 "No mental health diagnosis", add
				
		* VL
			rename hiv_rna lab_v
			foreach t in 100  {
				gen vf`t' = 0
				replace vf`t' = 1 if lab_v >= `t' & qualifier !="<"
				sum lab_v if vf`t' ==1
				tab qualifier if vf`t' ==1
			}
		*list patient lab_v qualifier vf100 vf200 vf400 vf1000 if lab_v ==40
					
		* Multivariable analysis: adjusted for age sex yoa and MH: 400 
			foreach f in 0 1 2 3 4 5 9 {
				mepoisson vf400 i.F`f' i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
				contrasts F`f', effect irr
				if `f' == 0 postsave F0, ciseparator("-") number(1) baselevels keep(var est varname label level id number) save("$temp/vf") varsuffix(0) heading baselab("1.00") sort(number0 id0) estlab("VL>400, aRR (95% CI)") dropcoef(0.F0) clean
				else postsave F`f', ciseparator("-") number(1) baselevels keep(var est varname label level id number) append("$temp/vf") varsuffix(0) heading baselabel("1.00") sort(number0 id0) dropcoefficient(h.F`f' 0.F`f') clean
			}
			
		* Multivariable analysis: adjusted for age sex yoa and MH: 100 1000
			foreach f in 0 1 2 3 4 5 9 {
				mepoisson vf100 i.F`f' i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
				contrasts F`j', effect irr
				if `f' == 0 postsave F0, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(1) heading baselab("1.00") sort(number0 id0) estlab("VL>100, aRR (95% CI)") dropcoef(0.F0) clean
				else postsave F`f', ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(1) heading baselabel("1.00") sort(number0 id0) dropcoefficient(h.F`f' 0.F`f') clean
			}
			
		* Multivariable analysis: adjusted for age sex yoa and MH: 100 1000
			foreach f in 0 1 2 3 4 5 9 {
				mepoisson vf1000 i.F`f' i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
				contrasts F`j', effect irr
				if `f' == 0 postsave F0, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(2) heading baselab("1.00") sort(number0 id0) estlab("VL>1000, aRR (95% CI)") dropcoef(0.F0) clean
				else postsave F`f', ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(2) heading baselabel("1.00") sort(number0 id0) dropcoefficient(h.F`f' 0.F`f') clean
			}
			
	* Dataset 
		use if CMA180_cat !=. using "C:/Data/IeDEA/Adh/v3/clean/analyseNVL", clear
		
		* Multivariable analysis: adjusted for age sex yoa and MH: 400 
			foreach f in 0 1 2 3 4 5 9 {
				mepoisson vf400 i.F`f' i.YOA ib2.age_cat##ib2.sex || patient: , vce(robust) irr  
				contrasts F`f', effect irr
				if `f' == 0 postsave F0, ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(3) heading baselab("1.00") sort(id0 varname0) estlab("Repeated, VL>400, aRR (95% CI)") dropcoef(0.F0) clean
				else postsave F`f', ciseparator("-") number(1) baselevels keep(var est varname label level id number) merge("$temp/vf") varsuffix(3) heading baselabel("1.00") sort(id0 varname0) dropcoefficient(h.F`f' 0.F`f') clean
			}		
		
														
		* Export table 
			use label est* var using "$temp/vf", clear 
			drop var
			capture putdocx clear
			putdocx begin, font("Arial", 8) landscape
			putdocx paragraph, spacing(after, 0) 
			putdocx text ("Table S5: Sensitivity analysis of associations between mental health diagnoses and viral non-suppression"), font("Arial", 9, black) bold
			putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
			putdocx table tbl1(., .), halign(right) font("Arial", 8)
			putdocx table tbl1(., 1), halign(left)
			putdocx table tbl1(1, .), halign(center) border(bottom, single) bold
			putdocx save "$tables/Table S5.docx", replace
			

	

	/* Table 3: Analysis of associations between CMA in the 1, 3, and 6 months before viral load testing and non-suppressed viral load (NVL) at the threshold of ≥200, ≥400, and ≥1000 copies/mL" 
		
		* Data 
			use "$clean/analyseNVL", clear
		
		* Multivariable analysis of factors associated with NVL
			
			* VF 200 
				qui mepoisson vf200 i.CMA30_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  
				qui contrasts CMA30_cat, effect irr
				postsave CMA30_cat, ciseparator("-") number(0) baselevels heading keep(var est varname label level id number) save("$temp/vf") varsuffix(0)  estlab("aOR (95% CI)") baselabel("1.00") collab("VL ≥200 copies/mL") 
							
				qui mepoisson vf200 i.CMA90_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA90_cat, effect irr
				postsave CMA90_cat, ciseparator("-") number(1) baselevels heading keep(var est varname label level id number) append("$temp/vf") varsuffix(0)  baselabel("1.00") 	
				
				qui mepoisson vf200 i.CMA180_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA180_cat, effect irr
				postsave CMA180_cat, ciseparator("-") number(2) baselevels heading keep(var est varname label level id number) append("$temp/vf") varsuffix(0)  baselabel("1.00") 
			
			* VF 400 
				qui mepoisson vf400 i.CMA30_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  
				qui contrasts CMA30_cat, effect irr
				postsave CMA30_cat, ciseparator("-") number(0) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(1)  estlab("aOR (95% CI)") baselabel("1.00") collab("VL ≥400 copies/mL") sort(number0 id0)
							
				qui mepoisson vf400 i.CMA90_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA90_cat, effect irr
				postsave CMA90_cat, ciseparator("-") number(1) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(1)  baselabel("1.00") sort(number0 id0) 	
				
				qui mepoisson vf400 i.CMA180_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA180_cat, effect irr
				postsave CMA180_cat, ciseparator("-") number(2) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(1)  baselabel("1.00") sort(number0 id0)			
		
			* VF 1000
				qui mepoisson vf1000 i.CMA30_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  
				qui contrasts CMA30_cat, effect irr
				postsave CMA30_cat, ciseparator("-") number(0) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(2)  estlab("aOR (95% CI)") baselabel("1.00") collab("VL ≥1000 copies/mL") sort(number0 id0) clean
							
				qui mepoisson vf1000 i.CMA90_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA90_cat, effect irr
				postsave CMA90_cat, ciseparator("-") number(1) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(2)  baselabel("1.00") sort(number0 id0) clean
				
				qui mepoisson vf1000 i.CMA180_cat ib2.age_cat##ib2.sex i.YOA || patient: , vce(robust) irr  		
				qui contrasts CMA180_cat, effect irr
				postsave CMA180_cat, ciseparator("-") number(2) baselevels heading keep(var est varname label level id number) merge("$temp/vf") varsuffix(2)  baselabel("1.00") sort(number0 id0) clean	
		
			
		* Export table 
			use label est* using "$temp/vf", clear 
			list, sep(`=_N')
			capture putdocx clear
			putdocx begin, font("Arial", 8)
			putdocx paragraph, spacing(after, 0)
			putdocx text ("Table 3: Adjusted odds ratios for associations between NVL at a threshold of ≥200, ≥400, and ≥1000 copies/mL and CMA in the 1, 3, and 6 months before VL testing"), font("Arial", 9, black) bold
			putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)
			putdocx table tbl1(., .), halign(right) font("Arial", 8)
			putdocx table tbl1(., 1), halign(left)
			putdocx table tbl1(1, .), halign(center) bold
			putdocx table tbl1(2, .), halign(center) border(bottom, single) bold
			putdocx save "$tables/Table 3.docx", replace
			
	* Figure 3: Predicted probability of VF by CMA 	
	
		* Data 
			use "$clean/analyseNVL", clear
	
		* Model & predict 
			mepoisson  vf400 i.CMA180_cat i.YOA || patient: , vce(robust) irr  
			margins CMA180_cat, at(YOA==2)
			
		* Plot 
			marginsplot, scheme(cleanplots) ///
						 ytitle("Probability of viral load ≥400 copies/mL") ///
						 xtitle("CMA in the 6 months before VL testing, %") ///
						 title(" ", size(*1.2)) name("VL400", replace) ///
						 ysize(4) xsize(4.5) ///
						 ylab(0(.2).8) ///
						 graphregion(margin(b-2 t-2))
						 // text(.8 -1.2 "A", size(*1.5)) 
					
			* Export figure
				graph export "$figures/Figure 3.tif", as(tif) name(VL400) replace  width(1200)
					
			* Export figure in word document  
				capture putdocx clear
				putdocx begin, font("Arial", 8)
				putdocx paragraph, spacing(after, 8 pt)
				putdocx text ("Figure 3. Predicted probability of NVL at a threshold of ≥400 copies/mL for each CMA strata"), font("Arial", 9, black) bold 
				putdocx paragraph, spacing(after, 0)
				putdocx text ("CMA was assessed in the 6 months before viral load testing. Error bars show 95% confidence intervals."), font("Arial", 9, black)  
				putdocx image "$figures/Figure 3.tif"
				putdocx pagebreak
				putdocx save "$figures/Figure 3.docx", replace
					
					 
		
	
