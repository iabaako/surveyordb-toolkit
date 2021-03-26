*! surveryordb tookit, jun 2018 
*! Ishmail Azindoo Baako

program define surveyordb
	* written in stata 15.1; Requires stata version 13
	version 13
	* save session that invoked the program
	local version: di _caller()
	version `version'
	
	* define tempfiles
	tempfile _request _database
	
	* check subcommand
	if !regexm(`"`1'"', "^(update|append|summary|select)") {
		di as err "surveyordb: Unknown subcommand `1' expecting subcommand update, append, summary or select"
		ex 198
	}
		
	* parse subcommand
	gettoken subcmd 0: 0
	surveyordb_`subcmd' `0'
end

* surveyordb_update
* program to update staff availability using contract request form
program define surveyordb_update
	syntax using/, REQuest(string) [sheet(string)] save(string) [replace]
	
	qui {
		
		* if sheet is not specified assume "Request"
		if "`sheet'" == "" loc sheet "Request"

		noi di
		noi di "surveyordb update" , "{hline}" 
		noi di
		
		noi di "{title:Details}"
		noi di "Database File" 			_column(25) "`using'"
		noi di "Contract Request File"	_column(25) "`request'"
		noi di "Contract Request Sheet"	_column(25) "`sheet'"
		noi di "New Database"			_column(25) "`save'"
		
		* check that using and saving data are not the same
		if "`using'" == "`save'" {
			di as err "{p}Warning: You are attempting to overwrite the current database. Specify a different filename in save(){p_end}" 
			ex 602
		}
				
		* import, clean and save contract request
		tempfile _request
		surveyordb_ImpConReq using "`request'", sheet("`sheet'") 
		save `_request'
		
		* show details of request file
		noi di
		noi di "{title:Summary of Contract Request Form}"
		noi di "Project" 			_column(25) "`r(project_acronym)'"
		noi di "Project Head" 		_column(25) "`r(project_head)'" 
		noi di "Project Manager" 	_column(25) "`r(project_manager)'" 
		noi di "Project Phase"		_column(25) "`r(project_phase)'" 
		noi di "Project Office"		_column(25) "`r(field_office)'"
		noi di "Observations" 		_column(25) `r(obs)'		
		
		* import database and append new dataset
		use "`using'", clear
		
		noi di
		noi di "{title:Summary of Surveyor Database}"
		noi di "Observations"				_column(25) `=_N'
		tab uniqueid
		noi di "Number of Field Staff"		_column(25) `r(r)' 
		
		append using `_request'
		cap save "`save'"
		if _rc == 602 & "`replace'" == "" {
			di as err "file `save' already exist. Specify replace option to overwrite existing file"
			exit 601
		}
		else save "`save'", replace
		
		noi di
		noi di "{title:Summary of updated Surveyor Database}"
		noi di "Observations"				_column(25) `=_N'
		tab uniqueid
		noi di "Number of Field Staff"		_column(25) `r(r)' 
		noi di 
		noi di "surveyordb update" , "{hline}" 
	}
end

* surveyordb_append
* program to append surveyor field monitoring output, field staff contracts 
program define surveyordb_append
	syntax using/, REQuest(string) [sheet(string)] FMOutput(string) save(string) [replace]
	
	qui {
		if "`using'" == "`save'" {
			di as err "{p}Warning: You are attempting to overwrite the current database. Specify a different filename in save(){p_end}" 
		}
		
		* if sheet is not specified assume "Request"
		if "`sheet'" == "" loc sheet "Request"
		
		noi di
		noi di "surveyordb append" , "{hline}" 
		noi di
			
		noi di "{title:Details}"
		noi di "Database File" 				_column(25) "`using'"
		noi di "Contract Request File"		_column(25) "`request'"
		noi di "Contract Request Sheet"		_column(25) "`sheet'"
		noi di "Field Monitoring Output"	_column(25) "`fmoutput'"
		noi di "New Database"				_column(25) "`save'"

		* tempfiles
		tempfile _fmoutput _newdata _database
		surveyordb_ImpFMOutput using "`fmoutput'"
		save `_fmoutput'
		
		* show details of request file
		noi di
		noi di "{title:Summary of Field Monitoring Output}"
		noi di "Project" 			_column(25) "`r(project)'"
		noi di "Project Acronym"	_column(25) "`r(project_acronym)'"
		noi di "Project Phase"		_column(25) "`r(project_phase)'"
		noi di "Research Area"		_column(25) "`r(research_area)'"
		noi di "Paper/CAPI"			_column(25) "`r(paper_or_capi)'"
		noi di "Project Head" 		_column(25) "`r(project_head)'" 
		noi di "Project Manager" 	_column(25) "`r(project_manager)'" 
		noi di "Project Phase"		_column(25) "`r(project_phase)'" 
		noi di "Project Office"		_column(25) "`r(field_office)'"
		noi di "Observations" 		_column(25) `r(obs)'		
		
		surveyordb_ImpConReq using "`request'", sheet("`sheet'") 
		
		* show details of request file
		noi di
		noi di "{title:Summary of Contract Request Form}"
		noi di "Project" 			_column(25) "`r(project_acronym)'"
		noi di "Project Head" 		_column(25) "`r(project_head)'" 
		noi di "Project Manager" 	_column(25) "`r(project_manager)'" 
		noi di "Project Phase"		_column(25) "`r(project_phase)'" 
		noi di "Project Office"		_column(25) "`r(field_office)'"
		noi di "Observations" 		_column(25) `r(obs)'		
		
		* merge datasets 1:1 using uniqueid and role
		cap merge 1:1 uniqueid role using `_fmoutput', assert(match) gen(_fmerge)
		if _rc == 9 {
			levelsof uniqueid if _fmerge == 1, loc (master_only) clean s(", ")
			levelsof uniqueid if _fmerge == 2, loc (using_only) clean s(", ")
			loc moc = wordcount("`master_only'")
			loc uoc = wordcount("`using_only'")
		
			if `moc' > 0 {
				di as err 	"{p}The following `moc' uniqueids are in the contract request form only: `master_only'{p_end}"
				* allow user to specify if they want to continue ir abort program
				loc _end 0
				while `_end' == 0 {
					di as err 	"{p}This descrepancy could be because a field staff was issued a contract but did" ///
								`" not work on the project so was never evaluated. Type "continue" into the command console if"' ///
								`" you want proceed with appending this data to the database, else type "abort" to stop this program{p_end}"' ///
								_request(p_break)
					if lower("$p_break") == "continue" drop if _fmerge == 1
					else if lower("$p_break") == "abort" ex 9
					if regexm(lower("$p_break"), "continue|abort") loc _end 1
					else loc _end 0
					noi di
				}
			}
			
			if `uoc' > 0 {
				if `moc' > 0 noi di
				di as err 	"{p}The following `uoc' uniqueids are in the field montoring output only: `using_only'{p_end}" ///
									"Please ensure that all staff in the field monitoring output are also captured in the contract request"
				ex 9
			}
		}
		
		* drop _fmerge
		drop _fmerge
		
		save `_newdata'
		
		* import surveyor database and append new data
		use "`using'", clear
		
		noi di
		noi di "{title:Summary of Surveyor Database}"
		noi di "Observations"				_column(25) `=_N'
		tab uniqueid
		noi di "Number of Field Staff"		_column(25) `r(r)' 

		
		* merge with contract database, remove already existing records before merging in
		merge 1:1 uniqueid startdate using `_newdata', nogen keep(master)
		append using `_newdata'
		drop contract_date
		
		* record language variables
		ds *_VERIFIED
		loc verification 	"`r(varlist)'"
		loc languages	 	= subinstr("`verification'", "_VERIFIED", "", .)
		
		* recode missing languages
		recode `languages' 		(. = 0) 
		recode `verification' 	(. = .n)
		
		if "`replace'" ~= "" save "`save'", replace
		else cap save "`save'"
		if _rc == 602 {
			di as err "file `save' already exist. Specify replace option to overwrite existing file"
			ex 602
		}
		
		noi di
		noi di "{title:Summary of updated Surveyor Database}"
		noi di "Observations"				_column(25) `=_N'
		tab uniqueid
		noi di "Number of Field Staff"		_column(25) `r(r)' 
		noi di 
		noi di "surveyordb update" , "{hline}" 

	}
end

* surveyordb_summary
* program to summarize surveydb data
program define surveyordb_summary
	syntax using/, REPort(string) date(string) [replace]
	noi di 	"`using'" 
	noi di  "`outfile'"
end

* surveyordb_select
* program to select field staff from surveyordb using recruitment request form
program define surveyordb_select
	syntax using/, REQuest(string) exclude(string) outfile(string) [replace]
	
	qui {
		* tempfiles
		tempfile _database _shortlist _request _exclude _evals _request_clean _transit

		noi disp
		noi disp "surveyordb select" , "{hline}"
		noi disp

		* import unavailable list and keep list of current trainees, temp and permanently unavailable
		import excel using "`exclude'", sheet(trainee) cellrange(B2) firstrow clear
		keep if inlist(currentstatus, "in progress", "scheduled")
		gen reason = "trainee on " + project
		keep uniqueid trainingends
		ren trainingends available_after

		* drop if the training has already ended
		keep if available_after >= date(lower(subinstr("`c(current_date)'", " ", "", .)), "DMY") + 14
		
		save `_exclude', emptyok

		import excel using "`exclude'", sheet(temporarily unavailable) cellrange(B2) firstrow clear
		keep if !missing(uniqueid)
		keep uniqueid to reason
		ren to available_after
		append using `_exclude'
		save `_exclude', emptyok replace

		import excel using "`exclude'", sheet(permanently unavailable) cellrange(B2) firstrow clear
		keep if !missing(uniqueid)
		keep uniqueid
		gen available_after = date("31dec2030", "DMY")

		append using `_exclude'
		save `_exclude', emptyok replace

		count 
		loc exclude_cnt `r(N)'

		* save database
		use "`using'", clear
		* merge in availability data from trainee workbook
		if `exclude_cnt' > 0 merge m:1 uniqueid using `_exclude', update nogen ///
			keep(master match match_update match_conflict)
		format %td available_after
		
		* include availability
		gen n = _n
		bys uniqueid (n): egen available_after_2 = max(enddate)
		replace available_after = available_after_2 if missing(available_after)
		drop if missing(professionalism)
		sort n
		drop n

		save `_database', replace

		* import sheets
		import excel using "`request'", describe 
		loc sheetcount = `r(N_worksheet)'
		loc req_sheet_count = `sheetcount' - 3

		* save the name of each sheet in a local
		forval i = 1/`sheetcount' {
			loc sheet_`i' "`r(worksheet_`i')'"
		}

		* display error message if no sheet is created
		if `req_sheet_count' == 0 {
			noi di as err "Request form is incomplete. At least 1 sheet containing criteria for selection must be included"
			exit 601
		}

		* import project details sheet and import values as locals
		import excel using "`request'", sheet("Project Details") allstr clear
		
		* export request details
		foreach num of numlist 5/9 15/17 21/23 {
			if C[`num'] == "" {
				noi di as err `"Missing value for "`=B[`num']'". Please enter a value at cell C`num'"'
				exit 198
			}
		}

		* export project details
		putexcel set "`outfile'", sheet(Request Details) replace
		putexcel B2:C2 = "PROJECT DETAILS", merge bold font(20)

		loc row = 3	
		noi disp "{hline}"	
		noi disp "REQUEST DETAILS"
		noi disp "{hline}"	

		loc row = 3
		foreach num of numlist 5/9 14/17 21/23 {
			noi disp "`=B[`num']'" _column(30) "`=C[`num']'"

			putexcel B`row' = "`=B[`num']'" C`row' = C[`num']
			loc ++row
		}

		loc check_date = C[22]

		* format request details sheet
		mata: format_details()

		* set sheet for report
		putexcel set "`outfile'", sheet("Report") modify
		putexcel B2 = "FIELD STAFF DISQUALIFIED PER REQUIRED CRITERIA", bold font(12)
		putexcel B3 = "Number of Field Staff in Database" B5 = "Criteria"  C5 = "# dropped"
		
		loc sheetin 0
		forval i = 1/`sheetcount' {

			loc sheetname "`sheet_`i''"	

			if !inlist("`sheetname'", "Template", "choices", "Project Details", "") {

				loc ++sheetin 

				noi disp "{hline}"
				noi disp as res "Sheet `sheetin' of `req_sheet_count': " "`sheetname'"
				noi disp "{hline}"

				use `_database', clear
				save `_shortlist', replace
				
				* import each sheet, run request agains surveyor db and export results to outfile
				import excel using "`request'", sheet("`sheetname'") allstr clear
				save `_request', replace
				
				* check that the position has been specified
				if D[4] == "" {
					noi disp as err `"{p}"Field Staff Position" has not been specified. Please specify position in cell D[4] of sheet "`r(worksheet_`i')'"{p_end}"'
					exit 198
				}

				* get headers for rquired criteria
				loc conds "lang loc pos proj proj_drop area paper_capi capi_soft phone_field quant_qual educ db_score gender"
				loc track_cond 1
				foreach num of numlist 11 34 45 56 65 74 85 91 98 104 110 116 125 {
					loc cond: word `track_cond' of `conds'
					loc `cond'_desc = A[`num'] 
					loc ++track_cond
				}

				* get specifications for language requirement
				
				if B[16] ~= "" {
					loc f_lang_cond ""
					loc f_lang_spec ""
					forval j = 16(4)32 {
						if B[`j'] ~= "" {
							* create a list of languages specified
							loc f_lang_spec = "`f_lang_spec'" + " " + ///
								itrim(trim(subinstr(upper(B[`j']), " ", "_", .) + " " + ///
								subinstr(upper(E[`j']), " ", "_", .) + " " + ///
								subinstr(upper(H[`j']), " ", "_", .)))
							
							loc f_lang_spec: list uniq f_lang_spec

							* create condition for language filter 
							loc lang_cond = "(" + subinstr(upper(B[`j']), " ", "_", .) + " >= " + "`=C[`j'+1]'"
							if E[`j'] ~= "" loc lang_cond = `"`lang_cond'"' + " & " + subinstr(upper(E[`j']), " ", "_", .) + " >= " + "`=F[`j'+1]'"
							if H[`j'] ~= "" loc lang_cond = `"`lang_cond'"' + " & " + subinstr(upper(H[`j']), " ", "_", .) + " >= " + "`=I[`j'+1]'"
							loc lang_cond = `"`lang_cond'"' + ")"

							if `"`f_lang_cond'"' ~= "" loc f_lang_cond = `"`f_lang_cond'"' + " | (" + `"`lang_cond'"' + ")"
							else loc f_lang_cond `"`lang_cond'"'
						}
					}
				}

				* location requirement: Check that location was specified
				#d;
				loc regions
					"ASHANTI
			        BRONG_AHAFO
			        CENTRAL
			        EASTERN
			        GREATER_ACCRA
			        NORTHERN
			        UPPER_EAST
			        UPPER_WEST
			        VOLTA
			        WESTERN"
			        ;
			     #d cr
			     
			     * loop through and check if the box is checked. If yes include in regexm expression
			     * I NB: If more regions are added after referendum, change forval range
			     loc regexm_cond ""
			     forval r = 1/10 {
			     	* determine which col to pull from
			     	if `r' <= 8 loc col "K"
			     	else loc col "L"

			     	* determine row
			     	if `r' <= 8 loc row = 35 + `r'
			     	else loc row = 35 + `r' - 8  

			     	if `col'[`row'] == "1" {
			     		* get value if region is checked
			     		loc reg_checked: word `r' of `regions'

			     		if "`regexm_cond'" == "" loc regexm_cond = "`reg_checked'"
			     		else loc regexm_cond = "`regexm_cond'" + "|" + "`reg_checked'"
			     	}
			     }
			
			    if "`regexm_cond'" ~= "" loc f_loc_cond "regexm(region, "`regexm_cond'")"
				
				* Previous experience on specific ipa position
				* define field staff position values by order in excel form
				loc pos_vals "2 3 12 4 6 14 7 5 8 1 13 10 11 9"
				loc inlist_cond = ""
				forval p = 1/`=wordcount("`pos_vals'")' {
					* determine which col to pull from
			     	if `p' <= 8 loc col "K"
			     	else loc col "L"

			     	* determine row
			     	if `p' <= 8 loc row = 46 + `p'
			     	else loc row = 46 + `p' - 8 

			     	if `col'[`row'] == "1" {
			     		* get value if position is checked
			     		loc pos_checked: word `p' of `pos_vals'

			     		if "`inlist_cond'" == "" loc inlist_cond = "`pos_checked'"
			     		else loc inlist_cond = "`inlist_cond'" + "," + "`pos_checked'"
			     	}
				}

				if "`inlist_cond'" ~= "" loc f_pos_cond "inlist(role, `inlist_cond')"
				
				* check for project specific criteria
				if E[53] ~= "" {
					forval s = 1/10 {
						* determine which col to pull from
				     	if `s' <= 5 {
				     		loc col_project "E"
				     		loc col_phase	"F"
				     	}
				     	else {
				     		loc col_project "H"
				     		loc col_phase	"I"
				     	}

				     	* determine row
				     	if `s' <= 5 loc row = 58 + `s'
				     	else loc row = 58 + `s' - 5 
	     	
				     	if `col_project'[`row'] ~= "" {
				     		if `"`f_proj_cond'"' == "" loc f_proj_cond = "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
				     		else loc f_proj_cond = `"`f_proj_cond'"' + " | " + "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
				     		if `col_phase'[`row'] ~= "" loc f_proj_cond = `"`f_proj_cond'"' + " & " + "project_phase == " + `"""' + upper("`=`col_phase'[`row']'") + `"""' + ")"
				     		else loc f_proj_cond = `"`f_proj_cond'"' + ")"
				     	}
					} 
				}

				* check for project to exclude
				if E[53] ~= "" {
					forval s = 1/10 {
						* determine which col to pull from
				     	if `s' <= 5 {
				     		loc col_project "E"
				     		loc col_phase	"F"
				     	}
				     	else {
				     		loc col_project "H"
				     		loc col_phase	"I"
				     	}

				     	* determine row
				     	if `s' <= 5 loc row = 67 + `s'
				     	else loc row = 67 + `s' - 5 
	     	
				     	if `col_project'[`row'] ~= "" {
				     		if `"`f_proj_drop_cond'"' == "" loc f_proj_drop_cond = "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
				     		else loc f_proj_drop_cond = `"`f_proj_drop_cond'"' + " | " + "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
				     		if `col_phase'[`row'] ~= "" loc f_proj_drop_cond = `"`f_proj_drop_cond'"' + " & " + "project_phase == " + `"""' + upper("`=`col_phase'[`row']'") + `"""' + ")"
				     		else loc f_proj_drop_cond = `"`f_proj_drop_cond'"' + ")"
				     	}

					} 
				}

				* condition for research_area
				#d;
				loc research_areas
					"
					"Agriculture"
			       	"Education"
			       	"Financial Inclusion"
			       	"Governance"
			       	"Health"
			       	"Peace and Recovery"
			       	"Small and Medium Enterprises"
			       	"Social Protection"
			       	"
			       	;
			    #d cr

			    loc regexm_cond ""
			    forval a = 1/8 {
			    	if K[`=75+`a''] == "1" {
			    		loc area: word `a' of `research_areas'
			    		if "`regexm_cond'" == "" loc regexm_cond = upper("`area'")
			    		else loc regexm_cond = "`regexm_cond'" + "|" + upper("`area'")
			    	}
			    }

			    if "`regexm_cond'" ~= "" loc f_area_cond = `"regexm(researcharea, "`regexm_cond'")"'

			    * condition for PAPER or CAPI
			    if E[88] ~= "" {
			    	if inlist(D[88], "1", "2") loc f_paper_capi_cond = "inlist(paper_or_capi, " + D[88] + " )"
			    	else {
			    		use `_shortlist', clear
			    		keep uniqueid paper_or_capi
			    		bys uniqueid: gen eval_order = _n

			    		reshape wide paper_or_capi, i(uniqueid) j(eval_order)
			    		egen paper_exp = anymatch(paper_or_capi*), v(1 3)
			    		egen capi_exp = anymatch(paper_or_capi*), v(2 3) 
			    		keep uniqueid *_exp

			    		gen paper_or_capi = 3 if paper_exp == 1 & capi_exp == 1

			    		loc f_paper_capi_cond = "inlist(paper_or_capi, 3)"
			    		save `_transit', replace

			    		use `_shortlist', clear
			    		drop paper_or_capi
			    		merge m:1 uniqueid using `_transit', nogen assert(match) keep(match)
			    		save `_shortlist', replace
			    	}

				}
				* condition for CAPI Software
				* first check that capi was selected
				use `_request', clear
				loc regexm_cond ""
				if regexm(E[88], "CAPI") {
					#d;
					loc capi_softwares
						""Blaise C.B.S"
       					 ODK
       					 SurveyCTO
       					 Tangerine
						"
						;
					#d cr
					
					forval c = 1/4 {
						if K[`=92+`c''] == "1" {
							if `"`regexm_cond'"' == "" loc regexm_cond = upper(subinstr("`:word `c' of `capi_softwares''", ".", "\.", .))
							else loc regexm_cond = `"`regexm_cond'"' + "|" + upper(subinstr("`:word `c' of `capi_softwares''", ".", "\.", .))
						} 
					}
				}	

				if `"`regexm_cond'"' ~= "" loc f_capi_soft_cond = `"regexm(capi_software, "`regexm_cond'")"'

				* check for phone or in-person interviewing
				if inlist(E[101], "Phone", "Field") loc f_phone_field_cond = "inlist(interview_mode, 3, " + D[101] + ")"
				else if E[101] == "Phone & Field" {
					use `_shortlist', clear
		    		keep uniqueid interview_mode
		    		bys uniqueid: gen eval_order = _n

		    		reshape wide interview_mode, i(uniqueid) j(eval_order)
		    		egen phone_exp = anymatch(interview_mode*), v(1 3)
		    		egen field_exp = anymatch(interview_mode*), v(2 3) 
		    		keep uniqueid *_exp

		    		gen interview_mode = 3 if phone_exp == 1 & field_exp == 1

		    		loc f_phone_field_cond = "inlist(interview_mode, 3)"
		    		save `_transit', replace

		    		use `_shortlist', clear
		    		drop interview_mode
		    		merge m:1 uniqueid using `_transit', nogen assert(match) keep(match)
		    		save `_shortlist', replace

		    		loc f_phone_field_cond = "inlist(interview_mode, 3)"
				}
				
				use `_request', clear
				* check for quantitative or qualitative 
				if E[107] ~= "" {
					if inlist(E[107], "Quantitative", "Qualitative") loc f_quant_qual_cond = "inlist(quantitative_or_qualitative, " + D[107] + ")"
					else {
						use `_shortlist', clear
			    		keep uniqueid quantitative_or_qualitative
			    		bys uniqueid: gen eval_order = _n

			    		reshape wide quantitative_or_qualitative, i(uniqueid) j(eval_order)
			    		egen quant_exp = anymatch(quantitative_or_qualitative*), v(1 3)
			    		egen qual_exp = anymatch(quantitative_or_qualitative*), v(2 3) 
			    		keep uniqueid *_exp

			    		gen quantitative_or_qualitative = 3 if quant_exp == 1 & qual_exp == 1

			    		save `_transit', replace

			    		use `_shortlist', clear
			    		drop quantitative_or_qualitative
			    		merge m:1 uniqueid using `_transit', nogen assert(match) keep(match)
			    		save `_shortlist', replace

			    		loc f_quant_qual_cond = "inlist(interview_mode, 3)"
					}
				
				}

				use `_request', clear
				* check for minimal educational qualification
				if E[113] ~= "" loc f_educ_cond = "education >= " + D[113]

				* check if user specified to ignore cut off
				if E[114] == "1" loc f_dscore_cond 0
				else loc f_dscore_cond 40 

				* check if user specified gender
				if inlist(E[129], "Female", "Male") loc f_gender_cond = "gender == " + D[129]
				
				save `_request', replace

				* APPLY REQUIRED CRITERIA
				use "`_shortlist'", clear
				* For each condition, check that it was specified and apply requirement
				
				tab uniqueid
				loc staff_count_full `r(r)'

				* if lang requirement: create language data which only inludes last profiency eval for the lang
				if `"`f_lang_cond'"' ~= "" {
					save `_shortlist', replace

					keep uniqueid enddate `f_lang_spec'
					gsort uniqueid -enddate
					by uniqueid: gen eval_order = _n

					* reshape data to wide format
					drop enddate
					recode `f_lang_spec' (0 = .)
					reshape wide `f_lang_spec', i(uniqueid) j(eval_order) 
					
					foreach lang_var in `f_lang_spec' {
						egen `lang_var' = rowfirst(`lang_var'*) 
					}
					
					keep uniqueid `f_lang_spec'
					recode `f_lang_spec' (. = 0)

					save `_transit', replace

					use `_database', clear
					keep uniqueid - comment

					merge m:1 uniqueid using `_transit', nogen assert(match) keep(match)
					lab val `f_lang_spec' language

					save `_shortlist', replace
				}

				* Create region data which only includes last 
				keep uniqueid enddate region
				gsort uniqueid -enddate
				by uniqueid: gen eval_order = _n
				drop enddate
				reshape wide region, i(uniqueid) j(eval_order)
				egen str region_str = rowfirst(region*)
				keep uniqueid region_str
				rename region_str region
				save `_transit', replace

				use `_shortlist'
				drop region
				merge m:1 uniqueid using `_transit', nogen assert(match) keep(match)
				order region, before(district)
				drop district town
				save `_shortlist', replace
				
				noi disp 
				noi disp "Number of Field Staff in Database" _column(90) "`staff_count_full'"
				noi disp 

				if `sheetin' == 1 putexcel C3 = `staff_count_full'

				* dtermine col to write report to
				alphacol `=2+`sheetin''
				loc col_index "`r(alphacol)'"

				if `"`f_pos_cond'"' ~= "" decode role, gen (role_str)
				loc row_index 7

				putexcel `col_index'6 = "`sheetname'"
				
				foreach cond in lang loc pos proj proj_drop area paper_capi capi_soft phone_field quant_qual educ gender {
					if `=_N' > 0 {
						if `"`f_`cond'_cond'"' ~= "" {
							* language requirement: Apply to only last known evaluation of language

							gen `cond'_qualified = `f_`cond'_cond'
							bys uniqueid: egen `cond'_keep = sum(`cond'_qualified)

							* drop if surveyors who do not meet specified conditions
							if "`cond'" == "proj_drop" {
									tab uniqueid if `cond'_keep
									loc `cond'_dropped = `r(r)'
									keep if !`cond'_keep
							}
							else {
								tab uniqueid if !`cond'_keep
								loc `cond'_dropped = `r(r)'
								drop if !`cond'_keep
							}

						drop `cond'_*
						}
						else loc `cond'_dropped "NA"
					}
					else loc `cond'_dropped 0

					noi disp "``cond'_desc'" _column(90) "``cond'_dropped'"

					putexcel B`row_index' = "``cond'_desc'" `col_index'`row_index' = "``cond'_dropped'"
					loc ++row_index
				}
				
				save `_shortlist', replace
				
				if `=_N' > 0 {
					* Generate weighted average scores
					gsort uniqueid -enddate
					by uniqueid: gen eval_order = _n
					drop if eval_order > 3
					by uniqueid: gen eval_count = _N

					* generate variable to hold weights
					* The ideal scenario is that everyone has at least 3 evals and then the scores are weighted by 50, 30, 20 rule
						* however if someone has 2 evaluations is weighted with the 60, 40 and single evals are weigted 100%
					gen eval_weights = 	cond(eval_order == 1 & eval_count == 3, 0.5, ///
										cond(eval_order == 2 & eval_count == 3, 0.3, ///
										cond(eval_order == 3 & eval_count == 3, 0.2, ///	
										cond(eval_order == 1 & eval_count == 2, 0.6, ///
										cond(eval_order == 2 & eval_count == 2, 0.4, 1)))))

					* generate db_score_weigted
					egen db_score = rowmean(professionalism communication independence teamwork compliance writing)
					replace db_score = float((db_score/5)) * 100 
					replace db_score = float(db_score) * float(eval_weights)
					bys uniqueid: egen db_score_weighted = sum(db_score)
					keep if eval_order == 1

					* apply database cut off
					drop if db_score_weighted <= float(`f_dscore_cond')
					loc dscore_dropped `r(N_drop)'
					noi disp "Weighted Average Score (`f_dscore_cond'%)" _column(90) "`dscore_dropped'"

					putexcel B`row_index' = "Weighted Average Score (`f_dscore_cond'%)" `col_index'`row_index' = "`dscore_dropped'"
					loc ++row_index
					
					keep uniqueid db_score_weighted
					
					merge 1:m uniqueid using `_shortlist', nogen keep(match)
					order db_score_weighted, after(writing)

					* drop unavailable staff
					
					drop if available_after >= date("`check_date'", "DMY")
					loc unavail_dropped `r(N_drop)'
					noi disp "Unavailable" _column(90) "`unavail_dropped'"

					putexcel B`row_index' = "Unavailable" `col_index'`row_index' = "`unavail_dropped'"
					loc ++row_index

					
					* save database
					save `_shortlist', replace

				}

				***
				* APPLY PREFERRED CRITERIA
				***

				* check that preferred criteria has been specified. 
									* apply additional required criteria
				use `_request', clear
				keep B G H
				keep if inlist(_n, 137, 139, 141, 143, 145, 147) & !missing(B)

				loc sort_count = `=_N'
				forval k = 1/`sort_count' {
					* save sorting criteria
					loc B`k' = B[`k']
					loc G`k' = G[`k']
					loc H`k' = H[`k']
				}

				use `_shortlist', clear
				loc sort_cond ""
				forval k = 1/`sort_count' {
					* use sorting criteria
					sortby `G`k'', value(`H`k'') id(uniqueid)

					if "`G`k''" == "project" loc G`k' "project_acronym"

					if `k' == 1 loc sort_cond = "-`G`k''_s"
					else loc sort_cond = "`sort_cond' -`G`k''_s"
				}

				bysort uniqueid: keep if _n == _N

				* apply sorting criteria and export
				if `sort_count' > 0 gsort `sort_cond'
				
				* generate rank
				gen rank = _n
				
				keep uniqueid - education `f_lang_spec' db_score_weighted rank
				
				putexcel B22 = "Number of Field Staff Shortlisted" `col_index'22 = `=_N'

				noi disp
				noi disp "Number of Field Staff Shortlisted" _column(90) "`=_N'"


				if `=_N' > 0 {

					export excel using "`outfile'", sheet("`sheetname'") sheetreplace first(var) cell(B2)

					* decode numeric columns with vall
					ds, has(vall)
					foreach var of varlist `r(varlist)' {
						decode `var', gen (`var'_str)
						order `var'_str, after(`var')
						drop `var'
						ren `var'_str `var'
					}	
					
					mata: format_export("`sheetname'")
				}
			}
		}

		mata: format_report(`req_sheet_count')
	}
end

* alphacol by chris boyer
program alphacol, rclass
	syntax anything(name = num id = "number")

	local col = ""

	while `num' > 0 {
		local let = mod(`num'-1, 26)
		local col = char(`let' + 65) + "`col'"
		local num = floor((`num' - `let') / 26)
	}

	return local alphacol = "`col'"
end

* program to apply individual required criteria
program define sortby
	syntax varname[, value(string)] id(varname)
	
	* define sorting criteria for strings
	if inlist("`varlist'", "project", "researcharea", "capi_software") {
		if "`varlist'" == "project" loc varlist "project_acronym"
		gen `varlist'_q = `varlist' == upper("`value'")
		bys uniqueid: egen `varlist'_s = max(`varlist'_q)
	}
	else if "`varlist'" == "db_score_weighted" gen `varlist'_s = `varlist'
	else {
		if inlist("`value'", "Paper", "Phone", "Quantitative", "Male") loc value 1
		else loc value 2

		gen `varlist'_q = inlist(`varlist',3, `value')
		bys uniqueid: egen `varlist'_s = max(`varlist'_q)
	}

	cap drop `varlist'_qualified
end


* program to export details
mata:
mata clear
void format_details()
{

	filename = st_local("outfile")
	sheetname = "Request Details"

	class xl scalar b
	b.load_book(filename)
	b.set_sheet(sheetname)

	b.set_sheet_gridlines(sheetname, "off")

	b.set_row_height(1, 1, 10)
	b.set_column_width(1, 1, 1)
	b.set_column_width(2, 2, 20)
	b.set_column_width(3, 3, 50)

	b.set_border((3, 14), (2, 3), "thin")
	b.set_left_border((3, 14), (2, 2), "thick")
	b.set_right_border((3, 14), (3, 3), "thick")
	b.set_top_border((3, 3), (2, 3), "thick")
	b.set_bottom_border((14, 14), (2, 3), "thick")

	b.close_book()
	
}
end

mata:
mata clear
void format_report(real scalar col_num)
{

	filename = st_local("outfile")
	sheetname = "Report"

	class xl scalar b
	b.load_book(filename)
	b.set_sheet(sheetname)

	b.set_sheet_gridlines(sheetname, "off")

	b.set_row_height(1,  1, 10)
	b.set_row_height(4,  4, 10)
	b.set_row_height(21,  21, 10)
	b.set_column_width(1, 1, 1)
	b.set_column_width(2, 2, 70)
	for (i = 3; i <= col_num + 3; i++) {
		b.set_column_width(i, i, 15)
	}

	col_last = col_num + 2

	b.set_border((3, 3), (2, 3), "thick")

	b.set_sheet_merge(sheetname, (5, 6), (2, 2))
	b.set_border((5, 20), (2, col_last), "thin")
	b.set_left_border((5, 20), (2, 2), "thick")
	b.set_right_border((5, 20), (col_last, col_last), "thick")
	b.set_top_border((5, 5), (2, col_last), "thick")
	b.set_bottom_border((20, 20), (2, col_last), "thick")

	b.set_border((22, 22), (2, col_last), "thick")

	b.close_book()

}
end

mata:
mata clear
void format_export(string scalar sheetname) {
	filename = st_local("outfile")

	class xl scalar b
	b.load_book(filename)
	b.set_sheet(sheetname)

	b.set_sheet_gridlines(sheetname, "off")

	b.set_row_height(1,  1, 10)
	b.set_column_width(1, 1, 1)

	for (i = 1; i <= st_nvar(); i++) {
		if (st_isstrvar(st_varname(i)) == 1) {
			column_width = colmax(strlen(st_sdata(., i))) + 2
			if (column_width < 9) {
				column_width = 9
			}
		}
		else {
			column_width = 9
		}
		b.set_column_width(i + 1, i + 1, column_width)
	}

	b.set_border((2, st_nobs() + 2), (2, st_nvar() + 1), "thin")
	b.set_top_border((2, 2),  (2, st_nvar() + 1), "thick")
	b.set_bottom_border((2, 2),  (2, st_nvar() + 1), "thick")
	b.set_left_border((2, st_nobs() + 2), (2, 2), "thick")
	b.set_right_border((2, st_nobs() + 2), (st_nvar() + 1, st_nvar() + 1), "thick")
	b.set_bottom_border((st_nobs() + 2, st_nobs() + 2), (2, st_nvar() + 1), "thick")
}
end
