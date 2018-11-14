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
	noi di 	"`using'"
	noi di	"`request'" 
	noi di  "`fmoutput'"
end
