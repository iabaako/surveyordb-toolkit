*! ImpFMOutput, jun 2018
*! part of surveyordb toolkit
*! program to import and clean field monitoring output
*! Ishmail Azindoo Baako

program define surveyordb_ImpFMOutput, rclass
	syntax using/
	
	* default contract request extension to .xlsx if extension is not specified
	if !regexm("`using'", "(\.xlsx|\.xls)$") loc using "`using'.xlsx"
	
	* Confirm that file exist and confirm that file and neccesary sheet exist.
	confirm file "`using'"
	foreach sheet in "Project Details" "Language" "Staff Evaluations" {
		import excel using "`using'", sheet("`sheet'") allstring clear
	}
	
	* create tempfiles
	tempfile _language
	
	* import and save project details in locals
	import exc using "`using'", sheet("Project Details") cellrange(B2:B10) allstr clear
	loc project		 		= B[1] 
	loc project_acronym 	= B[2]
	loc project_phase 		= B[3]
	loc paper_or_capi 		= B[4]
	loc capi_software 		= B[5]
	loc researcharea 		= B[6]
	loc field_manager 		= B[7]
	loc project_head 		= B[8]
	loc project_manager 	= B[9]
	
	* import language data, reshape and save in local
	import exc using "`using'", sheet("Language") cellrange(A2) ///
		firstrow case(lower) allstr clear
	drop if missing(proficiencyoral)
	loc lang_count `=_N'
	if `lang_count' > 0 {
		replace language = upper(trim(itrim(subinstr(language, " ", "_", .))))
	
		* change proficiencies to numeric
		ren proficiencyoral p_
		surveyordb_convert p_, default(proficiency) values(0) trim

		destring p_ fieldstaffid, replace
		drop fieldstaffname submissions
		reshape wide p_, i(fieldstaffid fieldstaffposition) j(language) str
		foreach var of varlist p_* {
			loc newname = subinstr("`var'", "p_", "", .)
			ren `var' `newname'
			gen `newname'_VERIFIED = cond(!missing(`newname'), 1, .n), after(`newname')
		}
		
		destring fieldstaffid, replace
		save `_language'
	}
	
	* import staff evaluations, clean and save in temp file
	import exc using "`using'", sheet("Staff Evaluations") cellrange(A3) ///
		firstrow case(lower) allstr clear
	ren _all, lower
	destring _all, replace
	drop if missing(fieldstaffid)
	
	* merge in local language 
	if `lang_count' > 0 merge 1:1 fieldstaffid fieldstaffposition using "`_language'", assert(match master) nogen
	drop submissions fieldstaffname
	ren (fieldstaffid 	fieldstaffposition 	complianceandeffectiveness 	writingskills 	interviewmode	activitytype) ///
		(uniqueid 		role				compliance					writing			interview_mode	quantitative_or_qualitative)		
		
	* add project details
	foreach var of newlist project project_acronym project_phase paper_or_capi capi_software researcharea field_manager project_head project_manager {
		gen `var' = upper("``var''")
	}
	
	* convert role to numeric
	surveyordb_convert role, default(role) values(1) upper trim
	* convert paper_or_capi to numeric numbers
	surveyordb_convert paper_or_capi, default(paper_or_capi) values(1) upper trim
	* convert phone_or_field to numeric
	surveyordb_convert interview_mode, default(interview_mode) values(1) upper trim
	* convert quantitaive_or_qualitative to numeric
	surveyordb_convert quantitative_or_qualitative, default(quantitative_or_qualitative) values(1) upper trim
	
	* return results
	return loc project			= "`project'"
	return loc project_acronym 	= "`project_acronym'"
	return loc project_phase	= "`project'"
	return loc paper_or_capi	= "`paper_or_capi'"
	return loc capi_software	= "`capi_software'"
	return loc project_head		= "`project_head'" 
	return loc researcharea		= "`researcharea'"
	return loc project_manager	= "`project_manager'" 
	return loc project_phase	= "`project_phase'" 
	return loc field_office		= "`field_office'"
	return loc obs				= `=_N'		
end 
