*! v2.0.0, 27mar2021
*! part of surveyordb toolkit
*! Ishmail Azindoo Baako

* import and clean contract request form
program define surveyordb_impCRF, rclass
	syntax using/ [, SHeet(string)]
	
	tempfile tmf_crf
	
	* confirm that file exist, else err 601 
	confirm file "`using'"

	* import and add project details
	import excel using "`using'", sheet("`sheet'") cellrange($crf_projcellrange) allstring clear
	keep if !missing(A) | !missing(B)
	replace A = trim(itrim(substr(A, 1, strpos(A, "[") - 1))) if regexm(A, "\[")
	
	foreach i in $crf_projrows {
		loc val`i'	"`=B[`i']'"
		return loc desc`i' "`=A[`i']'"
	}

	* import contract request form
	cap import excel using "`using'", sheet("`sheet'") cellrange($crf_startcell) first alls clear
	if _rc == 601 {
		if "`sheet'" == "Request" di as err ///
			"worksheet `sheet' not found. If this worksheet has been renamed specify new name in options sheet()"
		else di as err "worksheet `sheet' not found." 
	}

	* keep relevant vars only
	keep $crf_vars
	order $crf_vars
	
	egen nonmiss = rownonmiss(_all), strok
	drop if nonmiss <= 3 | type == "."
	drop type
	
	* generate row number to mark observations
	gen row = _n + 14
	
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
		ex 459
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
			
	* replace name 
	replace firstname = firstname + " " + middlename if !missing(middlename)

	loc i 1
	foreach j in $crf_projrows {
		loc var = word("$crf_projvars", `i')
		gen `var' = "`val`j''"
		loc ++i
	}
	
	* change cases for some of the variables
	foreach var of varlist firstname - education region - town role project_acronym - field_office {
		replace `var' = trim(itrim(upper(`var')))
	}

	* Convert some variables to numeric
		
	surveyordb_encode gender, labels($sdb_gender) values(1) upper trim
	surveyordb_encode education, labels($sdb_education) values(1) upper trim
	surveyordb_encode role, labels($sdb_role) values(1) upper trim

end
