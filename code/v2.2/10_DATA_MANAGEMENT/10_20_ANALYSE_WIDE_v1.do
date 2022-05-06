*** BASELINE TABLE 
					
	* First documented ART use 
		use "$clean/regimen", clear
		bysort patient (moddate): gen first_reg = drug[1]
		bysort patient (moddate): gen first_sd = moddate[1]
		format first_sd %tdD_m_CY
		list in 1/10
		keep if art ==1
		bysort patient (moddate): keep if _n ==1
		
	* Clean & rename 
		rename moddate art_sd 
		rename drug start_reg
		rename art_type start_type
		
	* End 
		merge 1:1 patient using "$source/FUPwide", keep(match) nogen
		
	* Baseline 
		merge 1:1 patient using "$source/BAS", keep(match) nogen assert(match using)
		
	* Missing date of birth 
		gen age_art_sd = floor((art_sd-birth_d)/365)
		drop if age_art_sd ==.
		assert inrange(age_art_sd, 15, 100)
		
	* N 
		count
		
	* Invalid 
		drop if invalid ==1
		drop invalid program
		
	* Vital status 
		merge 1:1 patient using "$source/VITAL", keep(match) nogen assert(match using)
		
	* Count 
		count if start < art_sd
		
	* Time to start 
		gen tts = art_sd - start
		list patient art_sd start tts if tts < 0
		replace start = art_sd if tts <0
		replace tts = art_sd - start
		sum tts
		assert tts !=.
		
	* Initiaters if ART start > 180 days after start of plan 
		capture drop initiator
		gen initiator = tts > 180 & tts !=.
		tab initiator, mi 
		tab start_type initiator, mi col
		replace initiator = 0 if start_type ==3
		replace initiator = 0 if start_type ==2 & year(art_sd) < 2019
		list patient art_sd start_reg art start_type first_reg first_sd start end tts initiator if initiator ==1 & start_type ==3, header(30)
		
	* Clean 
		compress
		drop art birth_d_a cod 
		
	* fup 
		gen fup = (end - art_sd)/365
		format fup %3.1fc
		sum fup, de
		
	* ART start before end of first plan (FUPwide) 
		drop if fup <= 0
		
	* ART start after 
		assert art_sd <= end	
		
	* Merge viral load in interval 
	
		* Intervals: year 1: (0.5-1.5]
		    //		 year 2: (1.5-2.5]
			
		* Define start and end of intervals
			local s1 = ceil(0.5 * 365) 
			local e1 = floor(1.5 * 365)
			forvalues j = 1/10 {
				qui local s`j' = ceil((`j' - .5) * 365) 
				qui local e`j' = floor((`j' + .5) * 365)
				di "year `j': `s`j'' - `e`j''"
			}
		
		* Generate variables for start (sY) and end (eY) of each year 
			forvalues j = 1/10 {
				gen s`j' = art_sd + ceil((`j' - .5) * 365) 
				gen e`j' = art_sd + floor((`j' + .5) * 365)
				format s`j' e`j' %tdD_m_CY
			}
			
		* Trucate intervals to follow-up duration  
			assert start < s1
			list patient art_sd end s1 e1 s2 e2 if s2 > end in 1/100
			assert end !=.
			listif patient art_sd end s1 e1 s2 e2 if  s1 > end , id(patient) sort(patient) sepby(patient) n(5)
			forvalues j = 1/10 {
				replace e`j' = end if e`j' > end & e`j' !=.
			}
			*list patient art_sd end s1 e1 s2 e2 if patient =="B001556160"
			*listif patient art_sd end s1 e1 s2 e2 if  s1 > end & s1 !=. , id(patient) sort(patient) sepby(patient) n(5)
			*listif patient art_sd end s1 e1 s2 e2 s3 e3 s4 e4 s5 e5, id(patient) sort(patient) sepby(patient) n(10) seed(1)
						
		* Merge viral load in range 
			forvalues j = 1/9 {
				qui rangejoin date s`j' e`j' using "$temp/vlLong", keepusing(vf200 vf400 vf1000 date) by(patient) 
				listif patient art_sd end s`j' e`j' vf200 vf400 vf1000 date if date !=., id(patient) sort(patient) sepby(patient date) n(1) seed(1) 
				qui bysort patient (date): keep if _n ==1
				di in red "year: `j'"
				tab vf1000 if art_sd
				rename date rna_d
				foreach var in vf200 vf400 vf1000 rna_d {
					rename `var' `var'_`j'
				}
			}
			assertunique pat
		
		* List  
			listif patient art_sd end s1 e1 rna_d_1 vf200_1 s2 e2 rna_d_2 vf200_2 s3 e3 rna_d_3 vf200_3 if patient=="B012338733", id(patient) sort(patient) sepby(patient) n(1) seed(1)
						
		* Missing gender 
			drop if sex ==3
			
		* Number of VL tests  
			egen VLs = rownonmiss(vf200_*)
			tab VLs
			
		* Sample 
			set seed 22122021
			gen sample = runiformint(1, 100)
			
		* Sort
			sort patient 
			compress
			
		* Less than x months of follow-up 
			drop if fup < 6/12
			
	* Save 
		save "$clean/analyseWide", replace

		
	

