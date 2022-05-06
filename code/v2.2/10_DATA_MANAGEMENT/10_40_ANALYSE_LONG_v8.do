*** PREPARE ANAYLSE LONG TABLE 
	
	* CMA adherence data in long format 
		use "$temp/cmaLong", clear
		gunique patient // 62,041
		
	* Merge analyseWide data 
		merge m:1 patient using "$clean/analyseWide", keepusing(art_sd birth_d sex initiator VLs) sorted keep(match) nogen
		gunique patient // 54,378	
						
	*  Merge viral load 
		sort patient date
		merge 1:1 patient date using "$temp/vlLong", sorted keep(match master) nogen
		
	* Exclude VL tests done before 180 days 
		gen diff = date-art_sd
		foreach var in vf200 vf400 vf1000 qualifier hiv_rna {
			capture replace `var' =. if diff < 182 
			capture replace `var' ="" if diff < 182 
		}
		list patient art_sd date cma* vf200 diff VLs if pat =="B002301551" & vf200 !=.
		drop diff
		
	* Drop person time before ART initiation 
		assert art_sd !=.
		drop if date < art_sd
		
	* MH diagnoses 
		
		* Loop over diagnoses 
			foreach j in 0 1 2 3 4 5 9 {
			
			* Merge mental health diagnoses 
				merge 1:1 patient date using "$temp/F`j'_D", sorted keep(match master) nogen keepusing(icd10_date)	
			
			* Carry diagnoses forward for x days 
				bysort patient (date): replace icd10_date = icd10_date[_n-1] if icd10_date ==. & icd10_date[_n-1] !=.
				gen int diff = date-icd10_date
				gen byte F`j' = icd10_date !=.  // history of mental illness 
				gen byte F`j'_90 = diff <= 90  // carry diagnoses forward for 90 days 
				gen byte F`j'_180 = diff <= 180
				gen byte F`j'_365 = diff <= 365
				drop icd10_date diff

			}
			
			* List 
				*ed patient date cma art_sd hiv_rna vf400 vf1000 icd10_date F9* diff if patient =="B000013915"		
				*ed patient date cma art_sd hiv_rna vf400 vf1000 icd10_date F9* diff if patient =="B000019670"
				*ed patient date cma art_sd hiv_rna vf400 vf1000 icd10_date diff F4* F9* if patient =="B000028430"
				*ed patient date cma art_sd hiv_rna vf400 vf1000 icd10_date diff F0* if patient =="B000142024"
				
	* Mean adherence: per week, months, quarter, half-year, and year 
		foreach t in w m q h y {
			if "`t'" == "w" local d = 7 
			if "`t'" == "m" local d = 30
			if "`t'" == "q" local d = 90 
			if "`t'" == "h" local d = 180 
			if "`t'" == "y" local d = 365 
			gen int `t' = floor((date - art_sd)/`d')+1
			assert `t' !=.
			bysort patient `t' (date): egen cma_`t' = mean(cma)  
			bysort patient `t' (date): egen N_`t' = count(cma) 
		}
		
		list patient art_sd date cma ///
									w cma_w N_w ///
									m cma_m N_m ///
									q cma_q N_q ///
									h cma_h N_h ///
									y cma_y N_y if patient =="B002301551", sepby(patient w) header(30)
									
	* Save 
		compress
		save "$temp/temp1", replace
		use "$temp/temp1", clear
						
	* Mean adherence over 30, 60, 90, 180, and 365 days prior to viral load test  
		
		* Carry lab_d backwards until new test is done 
			gen int lab_d = date if vf200 !=., before(qualifier)
			format lab_d %tdD_m_CY
			gen descending = date * -1 
			sort patient descending
			bysort patient (descending): replace lab_d = lab_d[_n-1] if lab_d ==. & lab_d[_n-1] !=.
		
		* Weeks prior to next viral load test 
			gen d = date-lab_d
			sort patient date
			list patient date lab_d d cma art_sd hiv_rna vf400 vf1000 if patient =="B002301551", sepby(patient date)
			
		* Weeks before test and previous test or first test and ART initiation
			bysort patient lab_d (date): egen minD = min(d) 
			list patient date lab_d d minD cma art_sd hiv_rna vf400 vf1000 if patient =="B000961021", sepby(patient date)
			
		* Mean CMA: set to missing if no enough weeks before test and previous test or first test and ART initiation
			foreach j in 30 60 90 180 365 {
				local k = `j' - 1
				bysort patient lab_d (date): egen cma`j' = mean(cma) if inrange(d, -`k', 0) & minD <=-`k' 
			}
			*ed patient date lab_d d minD cma art_sd hiv_rna vf400 vf1000 cma* if patient =="B002732473"
			format cma* %3.2f
			
		* Clean 
			drop descending d minD 
	
	* Mortality  
			
		* Merge death data 
			merge m:1 patient using "$clean/analyseWide", keepusing(death_d death_y cod* end) sorted assert(match) nogen	
			
		* Assert death after ART initiation 
			assert death_d > art_sd if death_d !=.
			
		* Indicator for death 
			gen death = 1 if death_d ==date 
			count if death ==1
			local N = `r(N)' 
			gunique pat if death_d !=. & death_d <=end 
			assert `N' ==  `r(unique)'
			replace death = 0 if death ==. 
			
		* Indicator by cause of death 
			replace cod1 = . if death!=1
			replace cod2 = . if death !=1
			rename cod1 death1
			rename cod2 death2
			foreach var in death1 death2 {
				replace `var' = 0 if `var' ==.
			}
			lab define cod1 0 "Alive", add
			lab define cod2 0 "Alive", add
			drop death_y death_d
			
		* Assert death is in last row of patient 
			bysort patient (date): assert _n ==_N if death ==1 
			
	* CD4 
		merge 1:1 patient date using "$temp/cd4Long", sorted keep(match master) nogen keepusing(cd4 cd4_date)
		bysort patient (date): replace cd4 = cd4[_n-1] if cd4[_n-1]!=. & cd4==.
		
					
	* Age group at VL test 
		gen age = floor((date-birth_d)/365)
		egen age_cat = cut(age), at(15,20,25,35,45,55,65,100) label
		*tabstat age, by(age_cat) stats(min max)
		lab define age_cat 0 "15-19" 1 "20-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65+", replace
		lab val age_cat age_cat 
		lab var age_cat "Age, y" // at beginning of each months on ART - time-varying 
						
	* Label 
		lab define F0 1 "Organic mental disorder", replace
		lab val F0* F0 
		lab define F1 1 "Substance use disorder", replace 
		lab val F1* F1		
		lab define F2 1 "Serious mental disorder", replace
		lab val F2* F2		
		lab define F3 1 "Depressive disorder", replace 
		lab val F3* F3
		lab define F4 1 "Anxiety disorder", replace 
		lab val F4* F4
		lab define F5 1 "Other mental disorders", replace 
		lab val F5* F5
		lab define F9 1 "Any mental disorders", replace 
		lab val F9* F9
		
	* Save 
		save "$clean/analyseLong", replace
		
	

