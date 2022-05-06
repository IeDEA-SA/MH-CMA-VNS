
capture program drop postsave
program define postsave
* version 1.0  AH 14 Jan 2022 
	syntax varlist(min=1) [, SAVE(string) APPEND(string) EFORM DROP(string) KEEP(string) FORMAT(string) HEADING BRACKETS INDENT(int 2) LABELFormat DROPCOEFficient(string) name(string) number(int -999) VARSUFfix(string) CLEAN MIDpoint BASELEVels CISEParator(string) MERGE(string) MERGEID(string) COLLAB(string) ESTLAB(string) SORT(string) BASELABel(string)] 
	* Indentation  
		forvalues iteration = 1/`indent' {
			local blanks = "`blanks'" + " "
		}
		* Save matrix 
		tempname M
		matrix `M' = r(table)'
		* Extract labels 
		local c = 1 
		foreach j in `varlist' {
			local labname : value label `j'
				qui levelsof `j'
				foreach n in `r(levels)' {
					local levels_`j' = "`r(levels)'"
					local `j'_`n' : label `labname' `n'
					// di "``j'_`n''" 
					local varlab_`j' : variable label `j'
				}
		}
		* Preserve 
		preserve
			* save estimated to dataset 
			qui clear
			qui svmat2 `M', names(col ) rnames(var)
			* eform
			if "`eform'" != "" { // 
				foreach var in b ll ul {
					qui replace `var'=exp(`var')
				}
			}
			* Format estimates
			if "`format'" == "" { // 
				format %4.2f b ll ul
			}
			if "`format'" != "" { // 
				format `format' b ll ul
			}
			* Brackets 
			if "`brackets'" != "" local l = "["	
			if "`brackets'" != "" local r = "]"	
			if "`brackets'" == "" local l = "("	
			if "`brackets'" == "" local r = ")"			
			* CISEParator
			if "`ciseparator'" == "" local S = "-"
			else local S = "`ciseparator'" 
			* Varname
			qui gen varname = regexr(var, "^[0-9]+bn.", "")
 			qui replace varname = regexr(var, "^[0-9]+.", "") if !regexm(var, "^[0-9]+bn.")
			* Level 
			qui gen level = regexs(0) if regexm(var, "^[0-9]+")	
			* ID 
			qui gen id = _n
			* Baselevel
			if "`baselevels'" != "" {
				qui bysort varname (id): gen n = _n  
				qui expand 2 if n ==1, gen(dup)
				qui replace dup = dup*-1
				sort id dup
				qui ds varname id dup n, not 
				foreach v of var `r(varlist)' {
					qui capture replace `v' = "" if dup ==-1
					qui capture replace `v' = . if dup ==-1
				}
			}
				* level of refcat 
				foreach j in `varlist' {
					qui levelsof level if varname =="`j'", clean 
					local p = "`r(levels)'"
					// di "Variable levels: `levels_`j'' ; present: `p'"
					local b = "`levels_`j''"
					foreach lll in `p' {
						local b = regexr("`b'", "`lll'", "") 
						// di "baselevel: `b'"
						local b = ltrim(trim("`b'"))
						qui capture gen dup = . 
						qui replace level = string(`b') if varname == "`j'" & dup == - 1 
						qui replace var = "`b'" + ".`j'" if varname == "`j'" & dup == - 1 
					}
				}
				drop id 
				qui destring level, gen(id) force
				qui replace id = id-0.1 if dup ==-1
				format id %3.1fc
			* Label 
			qui levelsof varname
			qui gen label = ""
			qui foreach j in `r(levels)' {
				qui levelsof level 
				foreach n in `r(levels)' {
					qui replace label =  "`blanks'" + "``j'_`n''" if varname == "`j'" & level =="`n'"
				}
			}
			* labelformat 
			if "`labelformat'" == "" format %-10s label 
			else if "`labelformat'" != "" format `labelformat' label 
			format %-10s var 
			* Combine 
			if "`format'" != "" local f = "`format'"
			else local f = "%3.2f"
			qui gen est = string(b, "`f'") + " `l'" + string(ll, "`f'") + "`S'" + string(ul, "`f'") + "`r'" 
			* Reflab 
				if "`baselabel'" == "" { 
					qui replace est = "ref." if dup ==-1
				}
				else {
					qui replace est = "`baselabel'" if dup ==-1
				}
			* Headline for categorical variables
			capture drop dup n 
			if "`heading'" != "" {
				qui bysort varname (id): gen n = _n  
				qui expand 2 if n ==1, gen(dup)
				qui replace dup = dup*-1
				sort id dup
				qui ds varname id dup n, not 
				foreach v of var `r(varlist)' {
					qui capture replace `v' = "" if dup ==-1
					qui capture replace `v' = . if dup ==-1
				}
				qui replace id = id-0.1 if dup ==-1	
				qui replace var = "h." + varname if dup ==-1	
				foreach j in `varlist' {
					qui replace label = "`varlab_`j''" if dup == -1 & varname == "`j'"
				}
				drop dup n
			}
			else qui gen heading = .
			* Drop coefficients
			foreach d in `dropcoefficient' {
				qui drop if regexm(var, "`d'")
			}
			* Midpoint
			if "`midpoint'" != "" qui replace est = subinstr(est, ".", "·", .) 
			* Estimate label 
			if "`estlab'" != "" {
				qui set obs `=_N+1'
				qui replace id = -1 if _N==_n
				qui replace est = "`estlab'" if _N==_n
				qui replace var = "estlab" if _N==_n
				sort id
			}	
			* Column label 
			if "`collab'" != "" {
				qui set obs `=_N+1'
				qui replace id = -2 if _N==_n
				qui replace est = "`collab'" if _N==_n
				qui replace var = "collab" if _N==_n
				sort id
			}
			* Name & number
			if "`name'" != "" qui gen name = "`name'"
			if "`number'" != "-999" qui gen number = `number'
			* varsuffix 
			qui ds label var, not 
			local varlist  `r(varlist)'
			if "`varsuffix'" != "" {
				foreach j of var `varlist' {
					rename `j' `j'`varsuffix'
				}
			}
			* Drop and keep variables 
			if "`drop'" != "" { // 
				drop `drop'
			}
			if "`keep'" != "" { // 
				keep `keep'
			}
			* Order 
			order var label est 
			* save 
			if "`save'" != "" {
				if "`sort'" != "" sort `sort' // sort option 
				save `save', replace 
			}
			* append 
			if "`append'" != "" {
				tempfile file 
				qui save `file'
				clear
				capture qui use `append', clear 
				qui append using `file'  
				if "`sort'" != "" sort `sort' // sort option 
				save `save', replace 
			}
			* merge
			if "`merge'" != "" {
				tempvar s
				gen `s' =_n
				tempfile file 
				qui save `file'
				clear
				capture qui use `merge', clear 
				local key = "var"
				if "`mergeid'" != "" local key = "`mergeid'"
				merge 1:1 `key' using `file', nogen update
				sort `s'
				drop `s'
				if "`sort'" != "" sort `sort' // sort option 
				save `save', replace 
			}
			* list 
			if "`clean'" == "" list, sep(`=_N')
			else list label est*, sep(`=_N') noheader
		* Restore 
		restore
	end 

