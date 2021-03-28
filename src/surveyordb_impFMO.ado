*! v2.0.0, 28mar2021
*! Ishmail Azindoo Baako

program define surveyordb_impFMO, rclass
	syntax using/

	* create tempfiles
	tempfile tmf_languages

	* Confirm that file exist and confirm that file and neccesary sheet exist.
	import exc using "`using'", clear
	foreach sheet in "Project Details" "Language" "Staff Evaluations" {
		cap import exc using "`using'", sheet("`sheet'") clear
		if _rc == 601 {
			disp as err "worksheet `sheet' not found in `using'"
			ex 601
		}
	}
	
	* import and save project details in locals
	import exc using "`using'", sheet("Project Details") cellrange($fmo_projcellrange) allstr clear
	
	loc i 1
	foreach var in $fmo_projvars {
		return loc desc`i' 	= A[`i']
		loc `var' 			= B[`i']
		loc ++i
	}


	* import language data, reshape and save in local
	import exc using "`using'", sheet("Language") cellrange(A2) first case(l) allstr clear

	drop if missing(proficiencyoral)
	loc lang_count `=_N'
	if `lang_count' > 0 {
		replace language = upper(trim(itrim(subinstr(language, " ", "_", .))))
		
		* change proficiencies to numeric
		ren proficiencyoral p_
		surveyordb_encode p_, labels($sdb_proficiency) values(0) trim
		
		destring p_ fieldstaffid, replace
		drop fieldstaffname submissions
		reshape wide p_, i(fieldstaffid fieldstaffposition) j(language) str

		foreach var of varlist p_* {
			loc newname = subinstr("`var'", "p_", "", .)
			ren `var' `newname'
			gen `newname'_VERIFIED = cond(!missing(`newname'), 1, .n), after(`newname')
		}
		
		destring fieldstaffid, replace
		save "`tmf_languages'"
	}
	
	* import staff evaluations, clean and save in temp file
	import exc using "`using'", sheet("Staff Evaluations") cellrange(A3) first case(l) allstr clear

	destring _all, replace
	drop if missing(fieldstaffid)
	
	* merge in local language 
	if `lang_count' > 0 merge 1:1 fieldstaffid fieldstaffposition using "`tmf_languages'", assert(match master) nogen
	drop submissions fieldstaffname
	ren (fieldstaffid 	fieldstaffposition 	complianceandeffectiveness 	writingskills 	interviewmode	activitytype) ///
		(uniqueid 		role				compliance					writing			interview_mode	quantitative_or_qualitative)		
	
	* add project details
	foreach var of newlist $fmo_projvars {
		gen `var' = upper("``var''")
		return loc `var' = upper("``var''")
	}
	
	* encode sdb vars
	surveyordb_encode role, labels($sdb_role) values(1) upper trim
	surveyordb_encode paper_or_capi, labels($sdb_paper_or_capi) values(1) upper trim
	surveyordb_encode interview_mode, labels($sdb_interview_mode) values(1) upper trim
	surveyordb_encode quantitative_or_qualitative, labels($sdb_quantitative_or_qualitative) values(1) upper trim
	
end 
