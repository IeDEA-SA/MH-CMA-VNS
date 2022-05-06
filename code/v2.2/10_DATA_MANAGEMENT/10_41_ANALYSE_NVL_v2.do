* PREPARE DATASET FOR ANALYSIS OF FACTORS ASSOCAITED WITH NVL 
		use "$clean/analyseLong", clear 
				
	* Keep only rows with result 
		keep if vf200 !=. 
		
	* Drop if adherence is missing 
		drop if cma180 ==.
		assert cma30 !=.
				
	* Drop tests during first 6 months 
		assert lab_d - art_sd >180 
		assert lab_d - art_sd <.
		
	* N
		gunique pat  // 28,785
				
	* Clean 
		drop w cma_w N_w m cma_m N_m q cma_q N_q h cma_h N_h y cma_y N_y
		
	* List 
		listif patient art_sd sex VLs lab_d qualifier hiv_rna vf200 vf400 vf1000 cma*, id(patient) sort(patient lab_d) sepby(patient) n(5) seed(1)
		
	* CMA group, Non-adherence 
		foreach j in 30 60 90 180 365 {
			gen CMA`j' = round(cma`j'*100)
			egen CMA`j'_cat = cut(CMA`j'), at(0,10,20,30,40,50,60,70,80,90,100,101) label
			replace CMA`j'_cat = 10 - CMA`j'_cat 
			lab define CMA`j'_cat 10 "0-9" 9 "10-19" 8 "20-29" 7 "30-39" 6 "40-49" 5 "50-59" 4 "60-69" 3 "70-79" 2 "80-89" 1 "90-99" 0 "100", replace
			lab val CMA`j'_cat CMA`j'_cat 
			tabstat CMA`j', by(CMA`j'_cat) stats(min max)
			gen NA`j' = 100-CMA`j' // non-adherence 
			local m = `j'/30
			lab var CMA`j'_cat "CMA `m', %"
		}
		
	* Years on ART 
		gen yoa = (lab_d-art_sd)/365
		format yoa %3.2f
		sum yoa
		assert inrange(yoa, 0.4986, 10)
		gen YOA = floor(yoa)
		lab var yoa "Time since baseline, y"
		
	* CD4 
		egen cd4_cat = cut(cd4), at(0,200,350,500,5000) label		
		tabstat cd4, by(cd4_cat) stats(min max)
		lab define cd4_cat 0 "<200" 1 "200-349" 2 "350-499" 3 "500+" 9 "Missing", replace
		replace cd4_cat = 9 if cd4_cat ==.
		lab val cd4_cat cd4_cat 
		lab var cd4_cat "CD4, y"
				
	* Save temp 
		save "$clean/analyseNVL", replace		
		