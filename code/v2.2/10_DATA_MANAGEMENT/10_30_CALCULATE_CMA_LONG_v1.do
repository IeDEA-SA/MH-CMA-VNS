*** CALCULATE CMAs

	* Data 
	    use "$temp/claims2", clear
		
	* Drop backbone	
		drop if backbone ==1
		
	* Add up duration by med_sd 
		sort patient med_sd
		bysort patient med_sd: egen d = total(duration)
		bysort patient med_sd: keep if _n ==1	
		replace duration = d 
		assert duration >= 0
		drop d
		drop drug class backbone
						
	* Calculate days late and early 
		sort patient med_sd 
		bysort patient (med_sd): gen late = med_sd-med_ed[_n-1]
		gen early = abs(late) if late < 0	
		replace early = 0 if early ==.
		list if patient =="B000004419", sepby(patient)
					
	* Late accounting for stock 
		
		* First row 
			list if patient =="B000004419" & med_sd, sepby(patient)
			gen lateS =., after(late)
			bysort patient (med_sd):  gen stock = 0 if _n ==1
			
		* Loop over other rows 
			gunique patient 
			forvalues j = 2/`r(maxJ)' {
				
				* Display 
					di in red "Iteration `j' of `r(maxJ)'"
					
				* LateS: late days - stock 
						qui bysort patient (med_sd): replace lateS = late if late <= 0 & _n ==`j' 
						qui bysort patient (med_sd): replace lateS = late-stock[_n-1] if late > 0 & _n ==`j' 
						
					* Update stock 
						qui bysort patient (med_sd): replace stock = stock[_n-1]+late*-1 if _n ==`j' 
						qui bysort patient (med_sd): replace stock = 0 if stock < 0 & _n ==`j'
						list if patient =="B000000369", sepby(patient)
						list if patient =="B000004419", sepby(patient)	
				}
	
	* Save 
		save "$temp/lateS", replace
		use "$temp/lateS", clear	
			
	* Clean 
		keep patient med_sd lateS
		
	* Duration of interval 
		bysort patient (med_sd): gen int d = med_sd[_n+1]-med_sd 
		
	* CMA of interval 
		bysort patient (med_sd): gen cma = 1-lateS[_n+1]/d
		replace cma = 1 if cma > 1 & cma !=.
		drop lateS

	* Date
		rename med_sd date
		
	* Expand by duration and change date 
		expand d
		bysort patient date: replace date = date + _n - 1
		drop d
	
	* Checks 
		gunique patient date
		assert `r(maxJ)' ==1
		bysort patient (date): assert date==date[_n-1]+1 if _n !=1
	
	* Save 
		save "$clean/cmaLong", replace
		
	

