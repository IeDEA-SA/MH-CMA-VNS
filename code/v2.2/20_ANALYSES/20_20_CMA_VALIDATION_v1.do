		
*** CMA VALIDATION 
		
	* Dataset 
		use "$clean/analyseNVL", clear
		gunique pat // 28,785
				
	* ROC curves 

		* Simple roc curve 
			foreach j in 30 90 180 365 {
				roctab vf400 NA`j' if NA180 !=.
			}
			
		* Simple roc curve 
			foreach j in 30 90 180 {
				roctab vf400 CMA`j'_cat if NA180 !=., detail
			}
			
	* Figure 2: ROC curves of the accuracy of CMA for predicting NVL
	
		* Run roc regression
			rocreg vf400 NA30 NA90 NA180 NA365, cluster(patient) probit ml 
			
		* Save AUC 
			preserve 
			regsave, ci
			keep if regexm(var, ":auc")
			gen auc = string(coef, "%3.2f") + " (" + string(ci_lower, "%9.2f") + "-" + string(ci_upper, "%9.2f") + ")"
			local i = 0
			foreach j in NA30 NA90 NA180 NA365 {
				local i = `i' + 1
				local `j' = auc[`i'] 
			}
			restore 
			
		* Rocplot 
			rocregplot, plot1opts(msymbol(i)) plot2opts(msymbol(i)) plot3opts(msymbol(i)) plot4opts(msymbol(i)) ///
			line1opts(lcolor("$blue"))  line2opts(lcolor("$green"))  line3opts(lcolor("$purple"))  line4opts(lcolor("$red")) rlopts(lcolor(black))   ///
			legend(label(5 "CMA 1") label(6 "CMA 3") label(7 "CMA 6") label(8 "CMA 12") order(5 6 7 8) ring(0) position(5) bmargin(medsmall) size(*1.1) )  ///
			scheme(cleanplots)  ysize(4) xsize(4)  ///
			graphregion(margin(b+16 l-0 r-0)) ///
			xtitle("False-positive rate (1-specificity)") ytitle("True-positive rate (sensitivity)") /// 
			text(-.25 +.5 "{bf:AUC (95% CI)}", j(left) size(small)) ///
				text(-.30 +.5 "CMA 1:   `NA30'", j(left) size(small)) ///
				text(-.35 +.5 "CMA 3:   `NA90'", j(left) size(small)) ///
				text(-.40 +.5 "CMA 6:   `NA180'", j(left) size(small)) ///
				text(-.45 +.5 "CMA 12: `NA365'", j(left) size(small)) ///
				name(roc, replace)
				
			* Export figures 
				*graph export "$figures/Figure 2.pdf", as(pdf) name(roc) replace  
				*graph export "$figures/Figure 2.wmf", name(roc) replace  
				graph export "$figures/Figure S2.tif", as(tif) name(roc) replace  width(1200)
					
			* Export figure in word document  
				capture putdocx clear
				putdocx begin, font("Arial", 8)
				putdocx paragraph, spacing(after, 8 pt)
				putdocx text ("Figure S2. ROC curves of the accuracy of CMA for predicting NVL"), font("Arial", 9, black) bold 
				putdocx paragraph, spacing(after, 0)
				putdocx text ("True-positive rate (sensitivity), false-positive rate (1-specificity), and area under the curve (AUC) of cumulative medication availability (CMA) assessed over 1, 3, 6, and 12 months before  viral load testing for predicting non-suppressed viral load (NVL) at a threshold of ≥400 copies/mL. 79,463 viral load values from 28,785 participants were included in the analysis. "), font("Arial", 9, black)  
				putdocx image "$figures/Figure S2.tif"
				putdocx pagebreak
				putdocx save "$figures/Figure S2.docx", replace
					

					 
		
	
