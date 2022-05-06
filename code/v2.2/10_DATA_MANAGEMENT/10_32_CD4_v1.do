*** Clean lab data 
	
	* CD4
		use "$source/CD4_A", clear
		sort patient
		sum lab_v 
		
	* Clean 
		keep patient lab_d lab_v 
		rename lab_v cd4
		
	* Deduplicate 
		duplicates drop 
		bysort patient lab_d: gen N =_N
		listif * if N>1, id(patient) sort(patient lab_d) sepby(patient) seed(10) n(3)
		drop N
		bysort patient lab_d: keep if _n ==1
		assertunique patient lab_d
		listif * , id(patient) sort(patient lab_d) sepby(patient) seed(10) n(3)
		rename lab_d cd4_date
		compress
		sort patient cd4_date 
		
	* Save 
		tempfile cd4
		save `cd4' 
		
*** DROP CD4 BEFORE ART START EXCEPT THE MOST RECENT    

	* Wide patient table 
	    use patient art_sd end using "$clean/analyseWide", clear
		
	* Merge CD4 
		merge 1:m patient using `cd4', keep(match) sorted nogen 
	
	* Drop test after end 
		drop if cd4_date > end
		assert cd4_date !=.
		
	* List 
		listif *, id(patient) sort(patient cd4_date) sepby(patient) n(5) seed(0)
	
	* Keep the most recent diagnoses before ART initiation for each group 
		gen diff = cd4_date - art_sd
		listif if diff > 0, id(patient) sort(patient cd4_date) sepby(patient) n(5) seed(0)
		listif if inlist(pat, "B009101184", "B010111769", "B010224458"), id(patient) sort(patient cd4_date) sepby(patient) n(5) seed(0)
		replace diff = . if diff > 0
		bysort patient (cd4_date): egen max = max(diff)
		drop if diff <0 & diff != max 
			
	* Clean 
		drop end 
	
	* N 
		count //  105,569
		compress
		
	* Set date to art_sd if icd10_date was before ART start to merge the most recent ICD10 diagnoses before start of ART to ART start
		gen int date = cd4_date 
		replace date = art_sd if diff <0    
		format date %tdD_m_CY
		assertunique patient date
		sort patient date
		drop diff max
				
	* Save 
		save "$temp/cd4Long", replace
		
	
		