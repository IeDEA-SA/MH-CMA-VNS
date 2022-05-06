* PREPARE DATASET FOR ANALYSIS OF FACTORS ASSOCAITED WITH CMA 
	
	* Loop over time windows  
		foreach t in w m q h y {
		
			* Days of time window 
				if "`t'" == "w" local d = 7 
				if "`t'" == "m" local d = 30
				if "`t'" == "q" local d = 90 
				if "`t'" == "h" local d = 180 
				if "`t'" == "y" local d = 365 
				
			* Data
				use "$clean/analyseLong", clear
			
			* Keep first row per interval 
				bysort patient `t' (date): keep if _n ==1
				gunique pat 
				
			* Clean 
				keep patient date art_sd sex initiator F* `t' cma_`t' N_`t' death1 death2 death end cd4 cd4_date age age_cat
							
			* Drop incomplete time intervals 
				drop if N_`t' < `d'
				gunique pat 
		
			* CMA as percent 
				replace cma_`t' = cma_`t'*100
				format cma_`t' %4.1f
		
			* Save
				save "$clean/analyseCMA`t'", replace		
				
		}
		
		* Reshape wide
				
			* Months 
				use patient m cma_m using "$clean/analyseCMAm", clear
				drop if m > 5*12  
				reshape wide cma_m, i(patient) j(m)
				saveold "$clean/CMAm_wide", replace version(12)	
				
			* Quarter 
				use patient q cma_q using "$clean/analyseCMAq", clear
				listif patient q cma_q, id(pat) n(2) seed(3) sort(patient q) sepby(pat) nolab
				drop if q > 5*4  
				reshape wide cma_q, i(patient) j(q)
				saveold "$clean/CMAq_wide", replace version(12)			
		
			* Half-year 
				use patient h cma_h using "$clean/analyseCMAh", clear
				listif patient h cma_h, id(pat) n(5) seed(3) sort(patient h) sepby(pat) nolab
				drop if h > 10  
				reshape wide cma_h, i(patient) j(h)
				saveold "$clean/CMAh_wide", replace version(12)	
				
		