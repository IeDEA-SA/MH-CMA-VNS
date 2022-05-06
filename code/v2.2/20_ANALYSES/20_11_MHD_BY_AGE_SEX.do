* Table 1: BASELINE CHARACTERISTICS 

	* Prepare dataset 
		use "$clean/analyseWide", clear
		keep patient art_sd start_reg start_type birth_d sex start end popgrp initiator fup
		
	* Merge adherence
		merge 1:m patient using "$clean/analyseCMAh", keepusing(h F9 F0 F1 F2 F3 F4 F5 age age_cat)
		
	* Drop patient with less than 6 months follow-up 
		sum fup if _merge ==1
		gunique pat if _merge ==1
		drop if _merge ==1
		sum fup
		drop _merge
	
	* Set F variables to 1 if 1 in last row 
		gunique patient if F9 ==1
		bysort patient (F9): replace F9 = F9[_N]
		count if F9 ==1 & h ==1
		lab define F9 0 "No mental health diagnosis" 1 "Mental health diagnosis", replace
		
	* Other disorders 
		forvalues j = 0/5 {
			bysort patient (F`j'): replace F`j' = F`j'[_N]
		}
		
	* ART reg
		lab define start_type 1 "NNRTI-based" 2 "II-based" 3 "PI-based", replace
		lab val start_type start_type
		
	* Keep first row 
		bysort patient (h): keep if _n ==1
		drop h
		
	* Table 
		header age_cat, saving("$tables/MHD") percentformat(%3.1fc) freqlab("N=") clean freqf(%6.0fc)
		percentages F9 age_cat if sex ==1, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") heading("Men") indent(2) columntotals
		forvalues j = 0/5 {		
			percentages F`j' age_cat if sex ==1, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") noheading indent(4)
		}
		percentages F9 age_cat if sex ==2, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") heading("Women") indent(2) columntotals
		forvalues j = 0/5 {		
			percentages F`j' age_cat if sex ==2, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") noheading indent(4)
		}
		percentages F9 age_cat, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") heading("Both sexes") indent(2) columntotals
		forvalues j = 0/5 {		
			percentages F`j' age_cat, append("$tables/MHD") percentformat(%3.1fc) clean freqf(%6.0fc) drop("0") noheading indent(4)
		}
	
	* Load and prepare table for export 
		tblout using "$tables/MHD", clear merge align format("%25s")
				
	* Create word table 
		capture putdocx clear
		putdocx begin, font("Arial", 8) landscape
		putdocx paragraph, spacing(after, 0) 
		putdocx text ("Table S1: Prevalence of mental health diagnoses at the end of follow-up by age and sex"), font("Arial", 9, black) bold 
		putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
		putdocx table tbl1(., .), halign(right)  font("Arial", 8)
		putdocx table tbl1(., 1), halign(left)  
		putdocx table tbl1(1, .), halign(center) bold 
		putdocx table tbl1(2, .), halign(center)  border(bottom, single)
		putdocx pagebreak
		putdocx save "$tables/TableS1.docx", replace 
		