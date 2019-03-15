clear all
cls

net install surveyordb, all replace from("C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit/ado")
* set trace on
surveyordb select using "X:\Box Sync\IPA_GHA_SCs-DMs private folder\Surveyor Database New\01_database/007_surveyor_database_190201.dta", ///
	request(C:\Users\Ishamial Boako\Box Sync\git\surveyordb-toolkit\excel/Recruitment Request Form_sample.xlsm) ///
	exclude(X:\Box Sync\IPA_GHA_SCs-DMs private folder\Surveyor Database New\02_unavailable/SurveyorDB_unavailable.xlsx) ///
	outfile(C:/Users/Ishamial Boako/Box Sync/git/surveyordb-toolkit/test/sample_shortlist.xlsx) replace
