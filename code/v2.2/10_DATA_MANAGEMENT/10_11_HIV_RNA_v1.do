*** Clean lab data 
	
	* HIV RNA data 
		use "$source/HIV_RNA", clear
		sort patient
		sum lab_v if qualifier =="<"
		
	* VL
		foreach j in 100 200 400 1000 {
			gen vf`j' = 0
			replace vf`j' = 1 if lab_v >= `j'
			sum lab_v if vf`j' ==1
			tab qualifier if vf`j' ==1
		}
		
	* Clean 
		keep patient lab_d qualifier lab_v vf200 vf400 vf1000
		rename lab_v hiv_rna
		
	* Deduplicate 
		duplicates drop patient lab_d vf200 vf400 vf1000, force
		bysort patient lab_d: gen N =_N
		listif * if N>1, id(patient) sort(patient lab_d) sepby(patient) seed(10) n(3)
		drop N
		bysort patient lab_d: keep if _n ==1
		assertunique patient lab_d
		listif * if patient!="", id(patient) sort(patient lab_d) sepby(patient) seed(10) n(3)
		rename lab_d date
		compress
		
	* Save 
		save "$temp/vlLong", replace
		
	* Wide 
		use "$temp/vlLong", clear
		sum date, f
		drop if date > d(01/07/2020) | date < d(01/01/2016)
		sum date, f
		bysort patient (date): gen temp = _n
		replace temp = temp*-1
		bysort patient (temp): gen n = _n
		drop temp
		drop if n > 10
		list patient date vf200 vf400 vf1000 n in 1/40, sepby(patient) 
		keep patient date vf200 vf400 vf1000 n
		foreach var in date vf200 vf400 vf1000 {
			rename `var' `var'_ 
		}
		reshape wide date_ vf200_ vf400_ vf1000_, i(patient) j(n) 
		
	* Save 
		save "$temp/vlWide", replace