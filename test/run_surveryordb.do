clear all
cls

net install surveyordb, all replace from("C:\Users\Ishamial Boako\Documents\github\new\surveyordb-toolkit\ado")
* set trace on
surveyordb select using "17_surveyor_database_20210219_mb.dta", ///
	request("Recruitment Request Form  Tracta Endline_IA.xlsm") ///
	exclude(SurveyorDB_unavailable_2021.xlsx) ///
	outfile(sample_shortlist.xlsx) replace
