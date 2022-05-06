*** CLEAN PAHARMACY CLAIMS 

	*** Clean ARV claims

		* Medclaims 
			use patient med_sd med_id quantity nappi_code using "$source/MED_ATC_J", clear
			
		* Select ARVs  
			// Source for HIV drugs: https://www.hivbuch.de/wp-content/uploads/2020/11/HIV2020-21-1.pdf p46    
			// Source for ATC codes: https://www.whocc.no/atc_ddd_index/?code=J05A&showdescription=no
			keep if inlist(med_id, "J05AE09", "J05AE01", "J05AR10", "J05AE10", "J05AE08", "J05AE07") | /// PIs 
					inlist(med_id, "J05AF09", "J05AF05", "J05AF01", "J05AF02", "J05AF07", "J05AF06", "J05AF13") | /// NRTIs
					inlist(med_id, "J05AG05", "J05AG04", "J05AG06", "J05AG03", "J05AG01") | /// NNRTIs
					inlist(med_id, "J05AJ01", "J05AJ03") | /// IIs 
					inlist(med_id, "J05AX09", "J05AX07", "J05AX23") | /// EIs 
					regexm(med_id, "J05AR")  // combinations
					
		* Recode AZT/RTV as AZT  
			replace med_id ="J05AE08" if med_id =="J05AR23"
							
		* Merge start & end
			merge m:1 patient using "$source/fupWide", keep(match) keepusing(start end) nogen
					
		* Select claims in adults (age >= 15) 
			merge m:1 patient using "$source/BAS", keep(match master) keepusing(birth_d)
			assert _merge ==3
			drop _merge
			gen age = floor((med_sd-birth_d)/365)
			drop if age < 15
			drop if age ==.
			drop birth_d age
			
		* Drug name (abbreviation) 
			merge m:1 med_id using "$source/ARVs.dta", keep(match master) 
			assert _merge ==3
			tab med_id if _merge ==1
			drop _merge 

		* Number of patients 
			gunique pat // 67,214

		* List 
			*listif *, id(patient) sort(patient med_sd quantity) sepby(patient med_sd) seed(10) n(1)

		* Add up quantity by nappi_code & med_sd 
		
			* Min & max	
				sum quantity
			
			* Add up quantity by day and med_id 
				bysort patient nappi_code med_sd: egen q = total(quantity)
				*listif * if quantity<0 , id(patient) sort(patient med_sd quantity) sepby(patient med_sd) seed(10) n(15)
				bysort patient nappi_code med_sd: keep if _n ==1	
				drop quantity 
				rename q quantity
				drop if quantity ==0
				assert quantity > 0
				*listif *, id(patient) sort(patient med_sd med_id) sepby(patient med_sd) seed(10) n(15)
		
		* Save
			save "$temp/claims1", replace
			
	*** Define daily dose 
	
		* Calculate does base on time to next claim 
			use "$temp/claims1", clear
			sort patient med_id med_sd
			list if patient =="B009778191", sepby(patient drug)
			bysort patient med_id (med_sd): gen days = med_sd[_n+1]-med_sd
			gen dose = quantity/days
			gen mean_dose = dose 
			replace mean_dose = 30 if dose >= 30 & dose !=. // trucate at 30
			*listif patient med_sd med_id nappi_code drugname drug drug_type quantity days dose, id(patient) sort(patient med_sd med_id) sepby(patient med_sd) seed(10) n(5)

		* Mean, median, IQR, p10 & p90 dose by nappi 
			collapse (mean)mean_dose=mean_dose (median)med_dose=dose (p10)p10_dose=dose (p25)p25_dose=dose (p75)p75_dose=dose (p90)p90_dose=dose (count)N=dose, by(nappi_code med_id)
			gsort -N
			gen est_dose = . 
								
		* Estimate dose if p10 and p90 are value +- .25
			forvalues j = 1/4 {
				local min = `j'-0.25
				local max = `j'+.25
				replace est_dose = `j' if inrange(p10_dose, `min', `max') & inrange(p90_dose, `min', `max')
			}
			
		* Standard doses 
			* http://www.pbb.co.za/Nappi-Codes.aspx
			* see $source/MRPV173A0173September2018.xls for medication name and strength
			* see $source/MRPV207A0207July2021.xls for medication name and strength
			
			* Dose 
				gen dose = . 
				
			*  Lopinavir/ritonavir 200mg/50mg DDD 0.8g
				replace dose = 4 if nappi_code =="710028" 
				
			* Lamivudine-Zidovudine Tab 150-300 MG,  recommended dose of Lamivudine/Zidovudine is one tablet twice daily
				replace dose = 2 if inlist(nappi_code, "703627", "707300", "707971", "710596", "714827", "715669", "715992", "718081") | inlist(nappi_code, "720618", "723893", "723893", "875821") 
			
			* Lamivudine Tab 150 MG
				replace dose = 2 if inlist(nappi_code, "701282", "703378", "703378", "703716", "707962", "710602", "714830") | inlist(nappi, "717806", "717979", "718080", "821632")  			
			
			* Nevirapine Tab 200 MG
				replace dose = 2 if inlist(nappi_code, "703718", "704036", "707961", "709533", "710606", "714831", "717003") | inlist(nappi, "717492", "717834", "840645", "3000791") 			
				
			* Efavirenz-Emtricitabine-Tenofovir DF Tab 600-200-300 MG
   				foreach n in 715578 716630 716768 716768 717837 718672 718874 718925 719507 720428 720853 721197 721430 721497 721720 723676 723890 3000260 3001080 3001233 3001860 3002598 3000291 3002312 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
			
			* Emtricitabine-Tenofovir Disoproxil Fumarate Tab 200-300 MG	
				replace dose = 1 if inlist(nappi_code, "720869", "708254", "715071", "715091", "715579", "715997", "715997", "717275") | inlist(nappi, "717981", "720242", "721498", "723307", "723717") 
					
			* Zidovudine Tab 300 MG 
				replace dose = 2 if inlist(nappi_code, "703712", "704038", "707960", "709531", "710600", "714829", "717984", "885317")  		
				
			* Abacavir Sulfate Tab 300 MG (Base Equiv)
				replace dose = 2 if inlist(nappi_code, "720837", "714098", "715012", "715063", "715347", "715493", "898531", "3001229", "3001229")   

			* Atazanavir Sulfate Cap 150 MG (Base Equiv)
				replace dose = 2 if inlist(nappi_code, "716208", "708257", "715828")    

			* Darunavir 600 MG; cave: 600mg tab only in pretreated adults, in non-pretreated adults 800mg! furthermore: 600mg once / day is given sometimes in children
				replace dose = 2 if inlist(nappi_code, "719711") 
				list if inlist(nappi_code, "719711")
				
			* MACLEODS NEVIRAPINE MCP 200MG Tab
				replace dose = 2 if inlist(nappi_code, "3000791")  
				
			*  Didanosine Delayed Release Capsule 400 MG
				replace dose = 1 if inlist(nappi_code, "715074", "704785", "715671")  

			* ABACAVIR 300MG KAVIMUN, this drug is also available as a solution
				replace dose = 2 if inlist(nappi_code, "3001229") 
				
			* Lamivudine Oral Soln 10 MG/ML -> 30 ml / day is the recommended dose
				list if inlist(nappi_code, "703715", "704041", "708708", "708713", "710603", "715969", "821640") 
				replace dose = 5 if inlist(nappi_code, "703715", "704041", "708708", "708713", "710603", "715969", "821640")   // standard dose 30, use 5 based on data 
			
			* Tenofovir Disoproxil Fumarate Tab 300 MG, one 300 mg tablet once daily if body weight at least 35kg																				
				replace dose = 1 if inlist(nappi_code, "715056")   
				
			* MACLEODS LAMIVUDINE MCP 150MG TAB
				replace dose = 2 if inlist(nappi_code, "721499")   
				
			* Lamivudine-Nevirapine-Stavudine Tab 150-200-30 MG, only for patients <60kg -> for patients >60kg: Lamivudine-Nevirapine-Stavudine Tab 150-200-40 MG
				replace dose = 2 if inlist(nappi_code, "707970", "709840", "715716", "717287", "718829")   	 
									
			* Dolutegravir-Lamivudine-Tenofovir DF Tab 50-300-300 MG
				foreach n in 3000426 3000435 3000522 3000532 3000532 3000571 3000572 3000580 3000584 3000585 3000596 3000600 3000600 3000600 3000600 3000600 3000605 3000636 3000956 3001858 3002693 3000596 {
					replace dose = 1 if nappi_code =="`n'"
				}

			* Edurant25 mg 
				replace dose = 1 if inlist(nappi_code, "720029")
				
			* Atazor 300mg 
				replace dose = 1 if inlist(nappi_code, "718217")
				
			* Abacavir Sulfate-Lamivudine Tab 600-300 MG
				replace dose = 1 if inlist(nappi_code , "707321", "717977", "722096", "722622")
				
			* Efavirenz Tab 600 MG
				replace dose = 1 if inlist(nappi_code, "703318", "709331", "709528", "709545", "710019", "710594", "715591", "716055", "717778") | inlist(nappi_code, "717978", "718099", "3000055") 
				
				
			* Efavirenz-Lamivudine-Tenofovir DF Tab 600-300-300 MG
				foreach n in  717780 718733 721547 723043 723043 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}
			
			* Atazanavir Sulfate-Ritonavir Tab 300-100 MG (Base Equiv)    
				foreach n in 3001247 3002048 3002269 3002386  {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}			

			* Atazanavir Sulfate-Ritonavir Tab 300-100 MG (Base Equiv)    
				foreach n in 3001247 3002048 3002269 3002386  {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* ABACAVIR/LAMIVUDINE/DOLUTEGRAVIR* 600MG/300MG/50MG
				foreach n in 722296 723019  {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* Didanosine Delayed Release Capsule 400 MG
				foreach n in 704783 715073 715670  {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* Abacavir Sulfate-Lamivudine Tab 600-300 MG
				foreach n in 707321 717977 722096 722622 722622 3001013 3002822 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* LAMIVUDINE CIPLA-LAMIVUDINE C-M 300MG 
				foreach n in 709337 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* Tenofovir Disoproxil Fumarate Tab 300 MG
				foreach n in 708253 714097 714097 714994 715056 715072 715993 717779 718283 718284 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		

			* LAMIVUDINE/TENOFOVIR* CIPLA-LAMIVUDINE & TENOFOVIR C-M 300/300MG
				foreach n in 718676 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		
				
			* Lamivudine Tab 300 MG
				foreach n in 715335 {
					replace dose = 1 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		

			* ZIDOVUDINE/LAMIVUDINE/NEVIRAPINE* 719620 MIVIRDO MKG 300/150/200
				foreach n in 3000106 719620 718350 716427 723626 {
					replace dose = 2 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			*  Invi-Rase Capsules (Nappi Code: 825697-019) 200 mg cap Adults, oral: 600 mg 8 hourly 
				list if nappi_code =="825697"
				replace dose = 9 if nappi_code =="825697"
				
			* Didanosine Chew Tab 100 MG
				foreach n in 703333 709872  {
					replace dose = 4 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		

			* Atazanavir Sulfate Cap 200 MG (Base Equiv)
				foreach n in 708258 715827 716209  {
					replace dose = 2 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		
				
			* ABACAVIR*	ASPEN ABACAVIR	APM	20MG/ML
				foreach n in 720866 713758 720838 714099 723640 715494 898538  {
					replace dose = 30 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}		

			* EFAVIRENZ* 710593 ERIGE NGI 200MG // 2 or 3, use 2 
				foreach n in 709529 710593 712070 712932 718601 720841  {
					replace dose = 2 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* Darunavir Ethanolate Tab 400 MG (Base Equiv)                
				foreach n in 3000049 3001998    {
					replace dose = 2 if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	
				
			* Kaletra 80mg/20mg Oral Solution
				foreach n in 700924  {
					replace dose = 10  if nappi_code =="`n'"
					list if nappi_code =="`n'"
				}	

			* Unknown use est_dose
				list if nappi_code =="3001778"
				replace dose = 1 if nappi_code =="3001778"
				
			* AZT 
				list if med_id =="J05AF01"
				list if nappi_code =="703713"
				replace dose = 4 if inlist(nappi_code, "3001778", "703713")
				
				
			* Unknown 
				total N if dose ==.
				gen temp = 1 if dose ==.
				replace dose = round(mean_dose) if temp ==1
				replace dose = 1 if dose ==.
				replace dose = 1 if dose ==0
				order nappi_code dose
				drop temp
							
			* Save 
				save "$temp/dose", replace

	*** Clean ARV claims   
	
		* Duration 
			
			* Merge dose and calculate duration 
				use "$temp/claims1", clear	
				drop drugname
				merge m:1 nappi_code using "$temp/dose", keepusing(dose) assert(match) nogen
				gen duration = quantity/dose
				assert duration !=.
								
			* Add up duration by day and med_id 
				bysort patient med_sd med_id: egen d = total(duration)
				list if patient =="B000154367", sepby(patient med_sd) // consider adjusting dose for patients on high dose based on refill gaps
				list if patient =="B009685783", sepby(patient med_sd)
				bysort patient med_sd med_id: keep if _n ==1	
				list if patient =="B009685783", sepby(patient med_sd)
				replace duration = d 
				assert duration > 0
				drop quantity d
				listif *, id(patient) sort(patient med_sd med_id) sepby(patient med_sd) seed(1) n(5)
				
				bysort patient med_sd drug: gen temp = _N
				list if temp >1
				
			* Trucate duration at 180 days 
				sum duration, de
				tab duration 
				tab nappi_code if duration > 180, sort
				tab drug if duration > 180, sort
				*listif * if duration >180 & drug =="AZT", id(patient) sort(patient med_sd med_id) sepby(patient med_sd) seed(2) n(10)
				replace duration = 180 if duration > 180 & duration !=.
				replace duration = 1 if duration < 1
				replace duration = round(duration)
			
		* Clean 
			drop nappi_code drug_type dose temp
			compress
		
		* Create table with one line per drug
		
			* Maximum of 3 drugs per line
				replace drug =trim(drug)
				assert wordcount(drug) <=3
				
			* Drug 1-3
				gen drug1=word(drug, 1) 
				gen drug2=word(drug, 2) 
				gen drug3=word(drug, 3) 
			
			* Drop duplicates and then reshape to get a single line per drug
				assertunique patient med_sd drug
				rename drug ttt
				reshape long drug, i(patient ttt med_sd) j(drug_nr)
				drop if drug==""
				drop drug_nr ttt
				
			* Add up duration by med_sd and drug 
				sort patient med_sd drug
				drop med_id
				list if patient =="B009685783", sepby(patient med_sd)
				bysort patient med_sd drug: egen d = total(duration)
				list if patient =="B009685783", sepby(patient med_sd)
				bysort patient med_sd drug: keep if _n ==1	
				replace duration = d 
				assert duration > 0
				drop d
							
			* End date 
				list if patient =="B009685783", sepby(patient med_sd)
				gen int med_ed = med_sd + duration, after(med_sd)
				format med_ed %tdD_m_CY
				sort patient med_sd drug
				list if patient =="B000004419", sepby(patient med_sd)
			
			* Drugs 
				tab drug, sort
				
			* Drop booster 
				drop if drug == "RTV"
			
			* Checks 
				assert med_sd < med_ed
				assert med_sd !=.
				assert med_ed !=.
				assert dur !=.
				assert drug !=""
				assert patient !=""
				
			* Drug class
				gen class = ""
				replace class = "EI" if inlist(drug, "MVC")
				replace class = "II" if inlist(drug, "DTG", "RGV")
				replace class = "PI" if inlist(drug, "ATV", "DRV", "LPV", "SQV")
				replace class = "NRTI" if inlist(drug, "ABC", "AZT", "D4T", "DDI", "TDF", "TAF", "3TC", "FTC")
				replace class = "NNRTI" if inlist(drug, "EFV", "ETV", "NVP", "RPV")
				assert class !=""
				
			* Drug type 
				gen byte backbone = inlist(class, "NRTI")
				
			* List & count
				count // 9,091,515
				list if patient =="B000004419" & med_sd < d(01/06/2012), sepby(patient med_sd)
				
			* Add row for end: end of study is treated like a claim with zero duration  
				drop if med_sd >= end
				bysort patient drug (med_sd): gen L = 1 if _n ==_N
				expand 2 if L ==1, gen(last)
				drop L
				replace duration =0 if last ==1
				replace med_sd = end if last ==1 
				replace med_ed = end if last ==1
				listif *, id(patient) sort(patient drug med_sd last) sepby(patient drug) n(1) seed(1) 
											
			* Save cleaned raw claims: one row per drug with duration based on standard dosing
				save "$temp/claims2", replace
				
	*** Join overlapping treatment episodes 
	
		* Data 
		    use "$temp/claims2", clear

		* Flag rows with overlapping episodes without accounting for stockpiling
			sort patient drug med_sd
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)
			bysort patient drug (med_sd): gen late = med_sd-med_ed[_n-1]
			gen early = abs(late) if late < 0
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)

		* Flag start of each episode
			gen sE = 1 if late > 0 & late !=.
			bysort patient drug (med_sd): replace sE = 1 if _n ==1
						
		* Episode number 
			gen episode = sE
			replace episode = 0 if episode ==.
			bysort patient drug (med_sd): replace episode = episode+episode[_n-1] if _n >1
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)
			list if patient =="B000000369" & med_sd < d(01/12/2019), sepby(patient drug)
			
		* Beginning and end of episode 
			bysort patient drug episode (med_sd): egen sd = min(med_sd)
			bysort patient drug episode (med_sd):egen ed = max(med_ed)
			bysort patient drug episode (med_sd): egen stock = total(early)
			format %tdD_m_CY sd ed 
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug episode)
			list if patient =="B000000369" & med_sd < d(01/12/2019), sepby(patient drug episode)
			bysort patient drug episode (med_sd): keep if _n ==1
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)
			
		* Dates 
			replace med_sd = sd
			replace med_ed = ed
			drop sd ed late early sE episode stock
			
		* Save: combinded episodes - not accounting for stockpiling
			save "$temp/claims3", replace
			
	*** Join overlapping episodes - accounting for stockpiling
			
		* Data 
		    use "$temp/claims2", clear
						
		* Flag rows with overlapping episodes
			sort patient drug med_sd 
			list if patient =="B000004419", sepby(patient drug)
			bysort patient drug (med_sd): gen late = med_sd-med_ed[_n-1]
			gen early = abs(late) if late < 0	
			replace early = 0 if early ==.
			list if patient =="B000004419", sepby(patient drug)
					
		* Late accounting for stock 
		
			* First row 
				list if patient =="B000004419" & med_sd, sepby(patient drug)
				gen lateS =., after(late)
				bysort patient drug (med_sd):  gen stock = 0 if _n ==1
			
			* Loop over other rows 
				gunique patient drug
				forvalues j = 2/`r(maxJ)' {
				
					* Display 
						di in red "Iteration `j' of `r(maxJ)'"
					
					* LateS: late days - stock 
						qui bysort patient drug (med_sd): replace lateS = late if late <= 0 & _n ==`j' 
						qui bysort patient drug (med_sd): replace lateS = late-stock[_n-1] if late > 0 & _n ==`j' 
						
					* Update stock 
						qui bysort patient drug (med_sd): replace stock = stock[_n-1]+late*-1 if _n ==`j' 
						qui bysort patient drug (med_sd): replace stock = 0 if stock < 0 & _n ==`j'
						list if patient =="B000000369", sepby(patient drug)
						list if patient =="B000004419", sepby(patient drug)	
				}
				
			* Save for CMA data preparation
				save "$temp/lateS", replace
									
			* No missings lateS
				bysort patient drug (med_sd): assert lateS !=. if _n >1
				
			* Add stock to last med_ed 
				bysort patient drug (med_sd): replace med_ed = med_ed + stock if _n ==_N
				
			* Clean 
				drop late early stock
				
		* Flag start of each episode
			gen sE = 1 if lateS > 0 & lateS !=.
			bysort patient drug (med_sd): replace sE = 1 if _n ==1
						
		* Episode number 
			gen episode = sE
			replace episode = 0 if episode ==.
			bysort patient drug (med_sd): replace episode = episode+episode[_n-1] if _n >1
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)
			list if patient =="B000000369" & med_sd < d(01/12/2019), sepby(patient drug)
			
		* Beginning and end of episode 
			bysort patient drug episode (med_sd): egen sd = min(med_sd)
			bysort patient drug episode (med_sd): egen ed = max(med_ed)
			format %tdD_m_CY sd ed 
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug episode)
			list if patient =="B000000369" & med_sd < d(01/12/2019), sepby(patient drug episode)
			bysort patient drug episode (med_sd): keep if _n ==1
			list if patient =="B000004419" & med_sd < d(01/12/2012), sepby(patient drug)
			
		* Dates 
			replace med_sd = sd
			replace med_ed = ed
			drop sd ed lateS sE episode
			
		* Save: combinded episodes - accounting for stockpiling
			save "$temp/claims4", replace
										
	*** Create table with one line per regimen 
			
		* Genrate able with treatment switches 
			use "$temp/claims4", clear
			drop if last ==1
			drop start end
			sort patient med_sd 
			list if patient =="B000000369", sepby(patient med_sd)
			list if patient =="B000154367", sepby(patient med_sd)
			gunique pat // 68,895
			rename med_sd start 
			rename med_ed stop
			keep patient start stop drug
			sort patient start drug
			list if patient =="B000004419" & start < d(01/06/2012), sepby(patient start)

		* Expand 
			expand 2, gen(temp)
			sort patient start temp
			list if patient =="B000004419" & start < d(01/06/2012), sepby(patient start)

		* Reset drugstart to drugstop for added lines to find all possible switch dates
			replace start = stop if temp==1 
			list if patient =="B000004419" & start < d(01/06/2012), sepby(patient start)

		* Keep only one of all possible treatment switch dates 
			count // 1,505,790
			bysort patient start: keep if _n==1
		
		* Keep list with all possible switch dates 
			keep patient start
			rename start moddate
			list if patient =="B000000369", sepby(patient)
		
		* Find corresponding drugs at each time

			* Mmerge table with one line per drug 
				mmerge patient using "$temp/claims4", ukeep(drug med_sd med_ed) 
				drop _merge
				sort patient moddate
				list if patient =="B000000369", sepby(patient moddate)
			
			* Copy drug to temp if patient was on drug at moddate 
				gen temp=drug if inrange(moddate, med_sd, med_ed-1)

			* Keep rows with drugs 
				gunique pat
				sort patient moddate drug temp
				list if patient =="B000000369", sepby(patient moddate drug)
				bysort patient moddate drug (temp): keep if _n ==_N
				gunique pat 
						
		* Reshape into wide format for each moddate  
			keep patient moddate temp 
			bysort patient moddate (temp): gen n=_n
			reshape wide temp, i(patient moddate) j(n)

		* Drug regimen 
			egen drug = concat(temp*) ,  punct(" ")
			replace drug= ltrim(drug)
			drop temp*

		*Number of drugs 
			gen num_art= wordcount(drug)
			
		*List
			list if patient =="B000000369", sepby(patient moddate drug)
					
		* Drug class
			gen ei = regexm(drug, "MVC")
			gen ii = regexm(drug, "DTG") | regexm(drug, "RGV")
			gen pi = regexm(drug, "ATV") | regexm(drug, "DRV") | regexm(drug, "LPV") | regexm(drug, "SQV") 
			gen nnrti = regexm(drug, "EFV") | regexm(drug, "ETV") | regexm(drug, "NVP") | regexm(drug, "RPV") 
			gen base = ei==1 | ii==1 | pi==1 | nnrti==1 
			gen nrti = 0
			foreach j in ABC AZT D4T DDI TDF TAF 3TC FTC {
				replace nrti = nrti + 1 if regexm(drug, "`j'")
			}
				
		* ART 
			gen art = 0 
			replace art = 1 if base ==1 & nrti >=2
			replace art = 1 if regexm(drug, "DTG") & regexm(drug, "RPV")
			replace art = 1 if regexm(drug, "DTG") & regexm(drug, "3TC")
			replace art = 1 if regexm(drug, "DTG") & regexm(drug, "FTC")
				
		* ART type  
			gen art_type = . 
			replace art_type = 1 if nnrti ==1 & nrti >=2
			replace art_type = 3 if pi ==1 & nrti >=2
			replace art_type = 2 if ii ==1 & nrti >=1	
			replace art_type = 4 if art_type ==. & drug !=""
			replace art_type = 9 if drug ==""
			lab define art_type 1 "NNRTI+2NRTI" 2 "II+NRTI" 3 "PI+2NRTI" 4 "Other" 9 "None", replace
			lab val art_type art_type
			tab art_type
			tab drug if art_type ==3, sort mi
							
		* Clean 
			drop ei ii pi nnrti base nrti num_art

		* Save - accounting for stockpiling
			save "$clean/regimen", replace
				
	