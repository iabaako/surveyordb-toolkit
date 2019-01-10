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
	syntax using/, REQuest(string) outfile(string) [replace]
	
	qui {
		* tempfiles
		tempfile _database _request _evals _request_clean

		noi disp

		* import project details sheet and import values as locals
		import excel using "`request'", sheet("Project Details") allstr clear
			* define locals
			loc acronym 	= C[5]
			loc code 		= C[6]
			loc grant 		= C[7]
			loc office  	= C[8]
			loc phase   	= C[9]
			loc sub_phase	= C[10]
			loc fm 			= C[14]
			loc head        = C[15]
			loc manager 	= C[16]
			loc sc    		= C[17]
			loc submission 	= C[21]
			loc training 	= C[22]
			loc field       = C[23]
			loc duration 	= C[24]


		* import sheets
		import excel using "`request'", describe 
		loc sheetcount = `r(N_worksheet)'
		forval i = 1/`r(N_worksheet)' {
			if !inlist("`r(worksheet_`i')'", "Template", "choices", "Project Details", "") {
				noi disp "Creating List from sheet " as res "`r(worksheet_`i')'"


				* import each sheet, run request agains surveyor db and export results to outfile
				import excel using "`request'", sheet("`r(worksheet_`i')'") allstr clear
				* define locals
				loc position  	= D[4]

				* check that language requirement has been specified
			
				if B[10] ~= "" {
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
				     		if "`f_proj_cond'" == "" loc f_proj_cond = "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
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
				     		if "`f_proj_drop_cond'" == "" loc f_proj_drop_cond = "(project_acronym == " + `"""' + upper("`=`col_project'[`row']'") + `"""'
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
			    	if D[`=75+`a''] == "1" {
			    		loc area: word `a' of `research_areas'
			    		if "`regexm_cond'" == "" loc regexm_cond = upper("`area'")
			    		else loc regexm_cond = "`regexm_cond'" + "|" + upper("`area'")
			    	}
			    }

			    if "`regexm_cond'" ~= "" loc f_area_cond = `"regexm(researcharea, "`regexm_cond'")"'
	
			    * condition for PAPER or CAPI
			    if inlist(E[88], "Paper", "CAPI") loc f_paper_capi_cond = "inlist(paper_or_capi, 3, " + D[88] + ")"
				
				* condition for CAPI Software
				* first check that capi was selected
				loc regexm_cond ""
				if E[88] == "CAPI" {
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
				noi disp "`f_phone_field_cond'"

				* check for quantitative or qualitative 
				if inlist(E[107], "Quantitative", "Qualitative") loc f_quant_qual_cond = "inlist(quantitative_or_qualitative, 3, " + D[107] + ")"

				* check for minimal educational qualification
				if E[113] ~= "" loc f_educ_cond = "education >= " + D[113]

				* check if user specified to ignore cut off
				if E[114] == "1" loc f_dscore_cond 0
				else loc f_dscore_cond 40 

				* check if user specified gender
				if inlist(E[129], "Female", "Male") loc f_gender_cond = "gender == " + D[129]
				
				save `_request'

				* APPLY REQUIRED CRITERIA
				use "`using'", clear
				* For each condition, check that it was specified and apply requirement
				
				if `"`f_pos_cond'"' ~= "" decode role, gen (role_str)
				foreach cond in lang loc pos proj proj_drop area paper_capi capi_soft phone_field quant_qual educ gender {
					if `=_N' > 0 {
						if `"`f_`cond'_cond'"' ~= "" {
							gen `cond'_qualified = `f_`cond'_cond'
							bys uniqueid: egen `cond'_keep = sum(`cond'_qualified)

							* drop if surveyors who do not meet specified conditions
							if "`cond'" == "proj_drop" keep if !`cond'_keep
							else drop if !`cond'_keep
							loc `cond'_dropped  = `r(N_drop)'
							drop `cond'_*
							noi di "`cond': ``cond'_dropped'"
						}
					}
				}
				
				save `_database'
				
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
					
					keep uniqueid db_score_weighted
					
					merge 1:m uniqueid using `_database', nogen keep(match)
					order db_score_weighted, after(writing)

					* save database
					save `_database', replace
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

				use `_database', clear
				forval k = 1/`sort_count' {
					* use sorting criteria
					sortby `G`k'', value(`H`k'') id(uniqueid)
				}

				bysort uniqueid: keep if _n == _N

				* apply sorting criteria and export
				forval k = 1/`sort_count' {
					gsort -`G`k''
				}

				* generate rank
				gen rank = _n

				export excel uniqueid - education `f_lang_spec' rank ///
					using "`outfile'.xlsx", sheet("`position'") sheetreplace first(var)

			}
		}
	}
end

* program to apply individual required criteria
program define sortby
	syntax varname[, value(string)] id(varname)
	
	* define sorting criteria for strings
	if inlist("`varlist'", "project", "researcharea", "capi_software") {
		bys uniqueid: gen `varlist'_qualified = `varlist' == upper("`value'")
		bys uniqueid: egen `varlist'_sortby = max(`varlist'_qualified)
	}
	else if "`varlist'" == "db_score_weighted" gen `varlist'_sortby = `varlist'
	else {
		if inlist("`value'", "Paper", "Phone", "Quantitative", "Male") loc value 1
		else loc value 2

		bys uniqueid: gen `varlist'_qualified = inlist(`varlist',3, `value')
		bys uniqueid: egen `varlist'_sortby = max(`varlist'_qualified)
	}

	cap drop `varlist'_qualified
end
