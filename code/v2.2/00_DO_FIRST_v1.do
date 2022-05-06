
////////////////////////////////////////////////////////////////////////////////
***DO FIRST 
////////////////////////////////////////////////////////////////////////////////

*** FILE PATHS 

* Define project
 	
	*Versions
		global vDD "v2"   
		
	*Project names 
		global project "IeDEA" 
		global concept "MH-CMA-VNS" 
	
	*Folders 
		global do "C:/Users/haas/Dropbox/Do"
		global science "C:/Users/haas/Dropbox/Science"
		global data "C:/Data"
		
	* ADO 
		sysdir set PERSONAL "C:/Repositories/MH-CMA-VNS/code/v2.2/90_ADO"
	
* Generate project folders 
		
	*Project-level   
		capture mkdir "$do/$project" 		
		capture mkdir "$science/$project"
		capture mkdir "$data/$project"
		
	*Concept-level   
		capture mkdir "$do/$project/$concept" 		
		capture mkdir "$science/$project/$concept"
		capture mkdir "$data/$project/$concept"
		
	*Version-level   
		capture mkdir "$data/$project/$concept/$vDD"
		
	*Science sub-folders
		foreach folder in concepts docs figures tables papers abstracts other literature {  
			capture mkdir "$science/$project/$concept/`folder'"
		}
		
	*Data sub-folders
		foreach folder in clean source temp orig {  
			capture mkdir "$data/$project/$concept/$vDD/`folder'"
		}
		
* Define macros for file paths 

	*Science sub-folders
		foreach folder in figures tables abstracts literature {  
			global `folder' "$science/$project/$concept/`folder'"
		}

	* Data sub-folders 
		foreach folder in clean source temp orig {  
			global `folder' "$data/$project/$concept/$vDD/`folder'"
		}
				
	* Version number 
		global V =  substr("$vDD", 2, .)
		
* Working directory 
	cd "$data/$project/$concept/$vDD/temp"

* Define other macros 

	* Define closing date 
		global close_d = d(01/07/2020)
		
	* Colors 
		global blue "0 155 196"
		global green "112 177 68"
		global purple "161 130 188"
		global red "185 23 70"
		*global red "206 102 128"
		
	* Current date 
		global cymd : di %tdCYND date("$S_DATE" , "DMY")
		di $cymd
		global cdate = date("$S_DATE" , "DMY")
		di $cdate
		
