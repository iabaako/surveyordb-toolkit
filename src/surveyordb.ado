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

		* include CO file
		cap findfile "surveyordb_val`co'.ado", path(PLUS;PERSONAL)
		if "`r(fn)'" == "" {
			disp as err "Country Office Code `co' is invalid." 
			ex 198
		}
		else include "`r(fn)'"
		
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
	syntax using/, crf(string) [sheet(string)] fmo(string) save(string) [replace]
	
	qui {
		
		**

	}
end

* surveyordb_summary
* program to summarize surveydb data
program define surveyordb_summary
	syntax using/, outfile(string) date(string) [replace]
			
		*

end

* surveyordb_select
* program to select field staff from surveyordb using recruitment request form
program define surveyordb_select
	syntax using/, crf(string) exclude(string) outfile(string) [replace]
	
	qui {
		
		*

	}
end
