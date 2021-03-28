*! v2.0.0, 27mar2021 
*! Ishmail Azindoo Baako

program define surveyordb
	
	version 14.2
	
	* check subcommand: Check that subcmd is one of the expected (summarise & summarize are the same)
	if !inlist(`"`1'"', "update", "append", "summarize", "summarise", "select") {
		di as err "surveyordb: unknown subcommand `1'"
		ex 198
	}
	
	* parse subcommand
	gettoken subcmd 0: 0
	if "`subcmd'" == "summarise" loc subcmd "summarize"

	* get countryoffice
	qui di regexm(`"`0'"', "co\([a-zA-Z]+\)")
	loc co = subinstr(substr(regexs(0), 4, .), ")", "", 1) 
	* include CO file
	cap findfile "surveyordb_val`co'.ado", path(PLUS;PERSONAL)
	if "`r(fn)'" == "" {
		disp as err "Country Office Code `co' is invalid." 
		ex 198
	}
	else qui include "`r(fn)'"
	
	surveyordb_`subcmd' `0'


end


* surveyordb_update
* program to update staff availability using contract request form 
program define surveyordb_update
	syntax using/, crf(string) [SHeet(string)] co(string) save(string) [replace]

	* define tempfiles
	* prefixing tempfiles with tmf so it is easy to find them
	tempfile tmf_request tmf_database

	qui {
		
		* default to request if sheet is not specified
		if "`sheet'" == "" loc sheet "Request"

		noi di
		noi di "surveyordb update" , "{hline}" 
		noi di
		
		noi di "{title:Details}"
		noi di "DATABASE FILE" 			_column(35) "`using'"
		noi di "CONTRACT REQUEST FILE"	_column(35) "`crf'"
		noi di "CONTRACT REQUEST SHEET"	_column(35) "`sheet'"
		noi di "NEW DATABASE"			_column(35) "`save'"
		
		* check that using and saving data are not the same
		if "`using'" == "`save'" {
			di as err "{p}Warning: You are attempting to overwrite the current database. Specify a different filename in save(){p_end}" 
			ex 602
		}

		* import, clean and save contract request form
		surveyordb_impCRF using "`crf'", sheet("`sheet'") 
		save "`tmf_request'"
		
		* show details of request file
		noi di
		noi di "{title:Summary of Contract Request Form}"
		loc i 1
		foreach j in $crf_projrows {
			loc var = word("$crf_projvars", `i')
			noi di "`r(desc`j')'" 		_column(35) "`=`var'[1]'"
			loc ++i
		}

		noi disp "OBSERVATIONS" 		_column(35) "`=_N'"		
		
		* import database and append new dataset
		use "`using'", clear
		
		noi di
		noi di "{title:Summary of database}"
		tab uniqueid
		noi di "OBSERVATIONS"			_column(35) `=_N'
		noi di "STAFF COUNT"			_column(35) `r(r)' 
		
		append using "`tmf_request'"
		save "`save'", `replace'
		
		noi di
		noi di "{title:Summary of updated Surveyor Database}"
		tab uniqueid
		noi di "OBSERVATIONS"			_column(35) `=_N'
		noi di "STAFF COUNT"			_column(35) `r(r)' 
		noi di 
		noi di "surveyordb update" , "{hline}" 
	}
end

* surveyordb_append
* program to append surveyor field monitoring output, field staff contracts 
program define surveyordb_append
	syntax using/, crf(string) [sheet(string)] fmo(string) co(string) save(string) [replace]

	* tempfiles
	tempfile tmf_fmo tmf_newdata tmf_database
	
	qui {

		* if sheet is not specified assume "Request"
		if "`sheet'" == "" loc sheet "Request"
		
		noi di
		noi di "surveyordb append" , "{hline}" 
		noi di
			
		noi di "{title:Details}"
		noi di "Database File" 				_column(35) "`using'"
		noi di "Contract Request File"		_column(35) "`crf'"
		noi di "Contract Request Sheet"		_column(35) "`sheet'"
		noi di "Field Monitoring Output"	_column(35) "`fmo'"
		noi di "New Database"				_column(35) "`save'"

		if "`using'" == "`save'" {
			di as err "{p}Warning: You are attempting to overwrite the current database. Specify a different filename in save(){p_end}" 
		}

		surveyordb_impFMO using "`fmo'"
		save "`tmf_fmo'"
		
		* show details of request file
		noi di
		noi di "{title:Summary of Field Monitoring Output}"
		loc i 1
		foreach var in $fmo_projvars {
			noi di "`r(desc`i')'" 		_column(35) "`r(`var')'"
			loc ++i
		}
		noi di "OBSERVATIONS" 		_column(35) `=_N'

		surveyordb_impCRF using "`crf'", sheet("`sheet'") 
		
		* show details of request file
		noi di
		noi di "{title:Summary of Contract Request Form}"
		loc i 1
		foreach j in $crf_projrows {
			loc var = word("$crf_projvars", `i')
			noi di "`r(desc`j')'" 		_column(35) "`=`var'[1]'"
			loc ++i
		}

		noi disp "OBSERVATIONS" 		_column(35) "`=_N'"			
		
		* merge datasets 1:1 using uniqueid and role
		cap merge 1:1 uniqueid role using "`tmf_fmo'", assert(match) gen(_fmerge)
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
		
		save "`tmf_newdata'"
		
		* import surveyor database and append new data
		use "`using'", clear
		
		noi di
		noi di "{title:Summary of Surveyor Database}"
		noi di "OBSERVATIONS"				_column(35) `=_N'
		tab uniqueid
		noi di "STAFF COUNT"				_column(35) `r(r)' 
		
		* merge with contract database, remove already existing records before appending in
		merge 1:1 uniqueid startdate using "`tmf_newdata'", nogen keep(master)
		append using "`tmf_newdata'"
		
		* recode language variables
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
		noi di "OBSERVATIONS"				_column(35) `=_N'
		tab uniqueid
		noi di "STAFF COUNT"				_column(35) `r(r)' 
		noi di 
		noi di "surveyordb update" , "{hline}" 

	}
end

* surveyordb_summary
* program to summarize surveydb data
program define surveyordb_summary
	syntax using/, outfile(string) co(string) [date(string) replace]
			
		**

end

* surveyordb_select
* program to select field staff from surveyordb using recruitment request form
program define surveyordb_select
	syntax using/, crf(string) exclude(string) outfile(string) co(string) [replace]
	
	qui {
		
		**

	}
end
