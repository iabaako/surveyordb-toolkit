*! ImpCONREQ, jun 2018
*! part of surveyordb toolkit
*! program to import and clean field staff contract request form
*! Ishmail Azindoo Baako

* import and clean contract request form
program define surveyordb_ImpConReq, rclass
	syntax using/ [, sheet(string)]
	
	tempfile _staff 
		
	* default contract request extension to .xlsx if extension is not specified
	if !regexm("`using'", "(\.xlsx|\.xls)$") loc using "`using'.xlsx"
	
	* confirm that file exist, else err 601 
	confirm file "`using'"

	* import contract request form
	cap import excel using "`using'", sheet("`sheet'") cellrange(A14) ///
		firstrow case(lower) allstring clear
		keep type - contract_end
	
	if _rc == 601 {
		if "`sheet'" == "Request" di as err ///
			"worksheet `sheet' not found. If this worksheet has been renamed specify new name in options sheet()"
		else di as err "worksheet `sheet' not found." 
	}
	
	egen nonmiss = rownonmiss(_all), strok
	drop if nonmiss <= 3 | type == "."
	
	* generate row number to mark observations
	gen row = _n + 13
	
	destring uniqueid, replace
	* check that ID var is numeric and is nonmissing
	cap confirm numeric var uniqueid
	if _rc == 7 {
		levelsof row if !regexm(uniqueid, "[0-9]"), loc (rows) clean
		di as err "uniqueid contains non numeric characters on row(s) `rows'."
		ex 7
	}
	cap assert !missing(uniqueid)
	if _rc == 9 {
		levelsof row if missing(uniqueid), loc (rows) clean
		di as err "uniqued_id contains missing values on row(s) `rows'"
		ex 9
	}
	cap isid uniqueid
	if _rc == 459 {
		duplicates tag uniqueid, gen (dups)
		levelsof row if dup, loc (rows) clean
		di as err "variable uniqueid has duplicate observations on rows `rows'"
		exit 459
	}
	
	* gen startdate and enddate and drop string dates vars
	foreach var of varlist contract_* nhis_expires { 
		gen `var'_tmp 	= date(`var', "DMY")
		drop `var'
	}
	ren (*_tmp) (*)
	ren (contract_start contract_end) ///
		(startdate enddate)
	format %td *date nhis_expires
		
	drop wage* emergency* nonmiss ipa_experience grant segment
	
	* replace name 
	replace firstname = firstname + " " + middlename if !missing(middlename)

	save `_staff'
	
	* import and add project details
	import excel using "`using'", sheet("`sheet'") cellrange(B2:B11) allstring clear
	loc project_acronym = B[2]
	loc project_head	= B[3]
	loc project_manager	= B[4]
	loc project_phase	= B[8]
	loc field_office	= B[9]
	
	* reimport staff data and add project details
	use `_staff', clear
	foreach name in project_acronym project_head project_manager project_phase field_office {
		gen `name' = subinstr("``name''", "_", " ", .)
	}
	
	* change cases for some of the variables
	foreach var of varlist firstname - education region - neigborhood id_type base role project_acronym - field_office {
		replace `var' = trim(itrim(upper(`var')))
	}

	* Convert some dataset values to numeric
	* gender
	surveyordb_convert gender, default(gender) values(1) upper trim encode
	* Education

	surveyordb_convert education, default(education) values(1) upper trim
	
	* convert roles to numeric
	surveyordb_convert role, default(role) values(1) upper trim
	
	* drop unneeded variable
	drop neigborhood row type nhis_expires fullname base middlename
	
	* return results
	return loc project_acronym 	= "`project_acronym'"
	return loc project_head		= "`project_head'" 
	return loc project_manager	= "`project_manager'" 
	return loc project_phase	= "`project_phase'" 
	return loc field_office		= "`field_office'"
	return loc obs				= `=_N'		

end
