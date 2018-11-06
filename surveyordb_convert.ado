*! convert, jun 2018
*! part of surveyordb toolkit
*! program to import and clean field monitoring output
*! Ishmail Azindoo Baako

* program to convert strings to numeric chars
program define surveyordb_convert
	#d;
	syntax 	varname, 
			[default(namelist min = 1 max = 1) 
			 labels(string asis) 
			 values(numlist integer min = 1 max = 2) 
			 upper 
			 lower
			 trim
			 encode]
		;
	#d cr
	
	* check that varname is a string
	confirm str var `varlist' 
	
	* clean up varname
	if "`upper'" 	~= "" replace `varlist' = upper(`varlist')
	if "`lower'" 	~= "" replace `varlist' = lower(`varlist')
	if "`trim'" 	~= "" replace `varlist' = trim(itrim(`varlist'))
	
	* define default labels
	#d;
	loc role 
		""SURVEYOR" 
		 "AUDITOR (FIELD/PHONE)" 
		 "AUDITOR (AUDIO)" 
		 "EDITOR" 
		 "NOTE TAKER" 
		 "FACILITATOR" 
		 "INDEPTH INTERVIEWER" 
		 "OBSERVER" 
		 "VIDEO CODER" 
		 "TRANSCRIPTIONIST" 
		 "TRANSLATOR" 
		 "DATA ENTRY OFFICER" 
		 "TEAM LEADER" 
		 "FIELD SUPERVISOR" 
		 "MOBILIZER" 
		 "CHILD MEASUREMENT" 
		 "ASSESSOR""
		;
	loc gender 
		""MALE" 
		 "FEMALE""
		;
	loc education 
		""DOCTORATE" 
		 "MASTERS" 
		 "BACHELORS" 
		 "HND" 
		 "DIPLOMA" 
		 "CERTIFICATE" 
		 "SSCE" 
		 "BECE""
		;
	loc proficiency 
		""None" 
		 "Elementary" 
		 "Limited Working" 
		 "Minimum Professional" 
		 "Full Professional" 
		 "Native""
		;
 	loc paper_or_capi 
		""PAPER" 
		 "CAPI" 
		 "PAPER/CAPI""
		;
	loc interview_mode 
		""IN-PERSON" 
		 "ON PHONE" 
		 "IN-PERSON/ON PHONE""
		;
	loc quantitative_or_qualitative 
		""QUANTITATIVE" 
		 "QUALITATIVE" 
		 "QUANTITATIVE/QUALITATIVE""
		;
	#d cr
	
	* check that options default and labels are not specified together
	if "`default'" ~= "" & "`labels'" ~= "" di as err "options defaults and labels are mutually exclusive"
	* if default is used, check that defaul value specified is in expected list
	else if "`default'" ~= "" { 
		if !regexm("`default'", "role|gender|education|proficiency|paper_or_capi|interview_mode|quantitative_or_qualitative") ///
			di as err "unknown default: `default'" _newline ///
			as err "{p}Expected default values are role, gender, education, proficiency, paper_or_capi, interview_mode or quantitative_or_qualitative"
		else loc labels "``default''"
	}
	* if neither default nor labels is specified; throw an err
	else if "`default'" == "" & "`labels'" == "" {
		di as err "Must specify either default or generate option"
	}
	
	* get firstval and increment 
	loc firstval: word 1 of `values'
	if wordcount("`values'") == 1 loc increment 1
	else loc increment: word 2 of `values'	
	
	loc i `firstval'
	foreach label in `labels' {
		replace `varlist' = "`i'" if `varlist' == "`label'"
		if "`encode'" ~= "" loc encodelab `"`encodelab' `i' "`label'""'
		loc i = `i' + `increment'
	}
	
	destring `varlist', replace
	cap confirm numeric var `varlist'
	if _rc {
		levelsof `varlist' if !regexm(`varlist', "[0-9]"), loc (invalid) clean s(", ")
		di as err `"unexpected values in `varlist': `invalid'"'
		ex 108
	}
	
	if "`encode'" ~= "" {
		lab define `varlist' `encodelab'
		lab values `varlist' `varlist'
	}
end
