*! v2.0.0, 27mar2021
*! part of surveyordb toolkit

* program to encode using supplied string and numeric list
* NB: stata encode program cannot encode using a loc unless it is in a label format
program define surveyordb_encode
	#d;
	syntax 	varname, 
			 labels(string asis) 
			 values(numlist integer min = 1 max = 2) 
			 [upper 
			 lower
			 proper
			 trim]
		;
	#d cr
	
	* check that varname is a string
	confirm str var `varlist' 
	
	* clean up varname
	if "`upper'" 	~= "" replace `varlist' = upper(`varlist')
	if "`lower'" 	~= "" replace `varlist' = lower(`varlist')
	if "`trim'" 	~= "" replace `varlist' = trim(itrim(`varlist'))
	
	* get firstval and increment 
	loc firstval: word 1 of `values'
	if wordcount("`values'") == 1 loc increment 1
	else loc increment: word 2 of `values'	
	
	loc i `firstval'
	foreach label in `labels' {
		replace `varlist' = "`i'" if `varlist' == "`label'"
		loc encodelab `"`encodelab' `i' "`label'""'
		loc i = `i' + `increment'
	}
	
	destring `varlist', replace
	cap confirm numeric var `varlist'
	if _rc {
		levelsof `varlist' if !regexm(`varlist', "[0-9]"), loc (invalid) clean s(", ")
		di as err `"unexpected values in `varlist': `invalid'"'
		ex 108
	}
	
	lab define `varlist' `encodelab'
	lab values `varlist' `varlist'

end
