*** MENTAL HEALTH DIAGNOSIS - FIRST DIAGNOSES 

	* Data 
	    use patient art_sd end using "$clean/analyseWide", clear
		
	* Merge ICD10 F diagnses 
		merge 1:m patient using "$source/ICD10_F", keep(match) sorted nogen keepusing(icd10_date icd10_code)
	
	* Categorize mental disorders 
		gen F = . 
		replace F = 0 if regexm(icd10_code, "F0")
		replace F = 1 if regexm(icd10_code, "F1")
		replace F = 2 if regexm(icd10_code, "F2") |  regexm(icd10_code, "F31")  
		replace F = 3 if regexm(icd10_code, "F32") | regexm(icd10_code, "F33") | regexm(icd10_code, "F34.1") 
		replace F = 4 if regexm(icd10_code, "F4")
		tab icd10_code if F==.
		replace F = 5 if F==.
		lab define F 0 "Organic mental disorders" 1 "Substance use disorders" 2 "Serious mental disorders" 3 "Depression" 4 "Anxiety disorders" 5 "Other mental disorders" 9 "Any disorder", replace
		lab val F F 
		tab F
		assert F !=.
		
	* Drop diagnoses after end
		drop if icd10_date >=end
		assert icd10_date !=.
		
	* List 
		listif *, id(patient) sort(patient icd10_date) sepby(patient F) n(5) seed(0)
		
	* Date of first diagnosis 
		bysort patient F: egen F_date = min(icd10_date)
		format F_date %tdD_m_CY
		bysort patient F: keep if _n ==1
		replace icd10_date = F_date
		drop F_date end icd10_code
		
	* Any disorder 
		preserve 
		bysort patient (icd10_date): keep if _n ==1
		replace F = 9 
		tempfile file 
		save `file'
		restore 
		append using `file'
		
	* Set icd10_date to art_sd if MH diagnosis was before ART initiation 
		replace icd10_date = art_sd if icd10_date < art_sd
		drop art_sd
		
	* List 
		listif *, id(patient) sort(patient icd10_date) sepby(patient F) n(5) seed(0)
		
	* N 
		count // 62,485
		compress
				
	* Save 
		save "$temp/F_ever", replace
		
	* F1-9 datasets 
		levelsof F
		foreach j in `r(levels)' {
			use "$temp/F_ever", clear
			keep if F ==`j'
			gen F`j' = 1 
			gen int date = icd10_date 
			format date %tdD_m_CY
			keep patient date icd10_date F`j'
			sort patient date
			save "$temp/F`j'_ever", replace
		}
		
		
*** MENTAL HEALTH DIAGNOSIS - KEEP ONE DIAGNOSES FOR EACH DATE AND GROUP AND THE MOST RECENT DIAGNOSES BEFORE OR ON ART START   

	* Data 
	    use patient art_sd end using "$clean/analyseWide", clear
		
	* Merge ICD10 F diagnses 
		merge 1:m patient using "$source/ICD10_F", keep(match) sorted nogen keepusing(icd10_date icd10_code)
	
	* Categorize mental disorders 
		gen F = . 
		replace F = 0 if regexm(icd10_code, "F0")
		replace F = 1 if regexm(icd10_code, "F1")
		replace F = 2 if regexm(icd10_code, "F2") |  regexm(icd10_code, "F31")  
		replace F = 3 if regexm(icd10_code, "F32") | regexm(icd10_code, "F33") | regexm(icd10_code, "F34.1") 
		replace F = 4 if regexm(icd10_code, "F4")
		tab icd10_code if F==.
		replace F = 5 if F==.
		lab define F 0 "Organic mental disorders" 1 "Substance use disorders" 2 "Serious mental disorders" 3 "Depression" 4 "Anxiety disorders" 5 "Other mental disorders" 9 "Any disorder", replace
		lab val F F 
		tab F
		assert F !=.
				
	* Drop diagnoses after end 
		drop if icd10_date >=end
		assert icd10_date !=.
		
	* List 
		listif *, id(patient) sort(patient icd10_date) sepby(patient F) n(5) seed(0)
		
	* Keep only one diagnose per date and group 
		bysort patient F icd10_date: keep if _n ==1
		
	* Any disorder 
		preserve 
		bysort patient icd10_date: keep if _n ==1
		replace F = 9 
		tempfile file 
		save `file'
		restore 
		append using `file'
		
	* List 
		listif *, id(patient) sort(patient icd10_date) sepby(patient icd10_date) n(5) seed(0)
		
	* Keep the most recent diagnoses before ART initiation for each group 
		gen diff = icd10_date - art_sd
		listif if patient =="B012721271", id(patient) sort(patient F icd10_date) sepby(patient F) n(5) seed(0)
		listif if patient =="B008547868", id(patient) sort(patient F icd10_date) sepby(patient F) n(5) seed(0)
		replace diff = . if diff > 0
		bysort patient F (icd10_date): egen max = max(diff)
		drop if diff <0 & diff != max 
			
	* Clean 
		drop end icd10_code
	
	* N 
		count //  126,813
		compress
				
	* Save 
		save "$temp/F_D", replace
		
	* F1-9 datasets 
		levelsof F
		foreach j in `r(levels)' {
			use "$temp/F_D", clear
			keep if F ==`j'
			gen F`j' = 1 
			gen int date = icd10_date 
			replace date = art_sd if diff <0 // set date to art_sd if icd10_date was before ART start to merge the most recent ICD10 diagnoses before start of ART to ART start 
			format date %tdD_m_CY
			*listif if patient =="B008547868", id(patient) sort(patient F icd10_date) sepby(patient F) n(5) seed(0)
			assertunique patient date
			keep patient date icd10_date F`j' 
			sort patient date
			save "$temp/F`j'_D", replace
		}
	

